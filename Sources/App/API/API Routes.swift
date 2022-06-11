import Vapor
import VoteExchangeFormat
import FluentKit

func APIRoutes(_ API: RoutesBuilder, groupsManager: GroupsManager){
	let chat = API.grouped("chat")
	chat.webSocket("socket", ":groupid", onUpgrade: joinChat)
	chat.webSocket("adminsocket", ":groupid", onUpgrade: joinChat)
	
	func joinChat(req: Request, socket: WebSocket) async{
		// Checks if the user is allowed to chat and whether the request is valid
		guard
			Config.enableChat,
			let user = try? req.auth.require(DBUser.self),
			let groupID = req.parameters.get("groupid"),
			let uuid = UUID(uuidString: groupID),
			let linker = try? await user
				.$groups
				.query(on: req.db)
				.join(parent: \.$group)
				.filter(\.$group.$id == uuid)
				.first(),
			linker.constituentCanChat()
		else {
			try? await socket.close()
			return
		}
		
		do{
			let dbGroup = try linker.joined(DBGroup.self)
			let group = await groupsManager.groupForGroup(dbGroup)
			
			
			let socketKind: ChatSocketController.SocketKind
			if req.url.path.hasSuffix("adminsocket/\(groupID)") {
				socketKind = .admin
			} else if req.url.path.hasSuffix("socket/\(groupID)") {
				if linker.isVerified{
					socketKind = .verified
				} else {
					socketKind = .unverified
				}
			} else {
				assertionFailure("This route should only be called with one of the two socket types above")
				try await socket.close()
				return
			}
			
			await group.socketController.connect(socket, userid: user.id!, socketKind: socketKind, db: req.db)
			
			
		} catch {
			try? await socket.close()
			return
		}
	}
	
	
	API.get{ _ throws -> Response in
		throw Abort(.badRequest)
	}
	
	/// userID: String
	/// joinPhrase: String
	API.post("join", use: joinGroup)
	func joinGroup(req: Request) async throws -> Response{
		try await App.joinGroup(req, groupsManager, forAPI: true)
	}
	
	API.get("getdata") { req async throws -> GroupData in
		let linker = try req.auth.require(GroupConstLinker.self, Abort(.unauthorized))
		let group = linker.group
		
		return await groupsManager
			.groupForGroup(group)
			.getExchangeData(for: linker.constituent.username, constituentsCanSelfResetVotes: group.settings.constituentsCanSelfResetVotes)
	}
	
	/// Returns full information (metadata, options, validators) regarding a vote only if the client are allowed to vote at the moment
	API.get("getvote", ":voteID", use: getVote)
	func getVote(req: Request) async throws -> ExtendedVoteData{
		let linker = try req.auth.require(GroupConstLinker.self, Abort(.unauthorized))
		let dbGroup = linker.group
		let group = await groupsManager.groupForGroup(dbGroup)
		let const = linker.constituent.asConstituent()
		guard
			let voteIDStr = req.parameters.get("voteID"),
			let vote = await group.voteForID(voteIDStr)
		else {
			throw Abort(.notFound)
		}
		
		let voteData: ExtendedVoteData
		let voteStatus = await group.statusFor(await vote.id())
		switch vote {
		case .alternative(let v):
			guard !(await v.hasConstituentVoted(const)) && voteStatus == .open else {throw Abort(.unauthorized)}
			voteData = await ExtendedVoteData(v, constituentID: const.identifier, group: group)
		case .yesno(let v):
			guard !(await v.hasConstituentVoted(const)) && voteStatus == .open else {throw Abort(.unauthorized)}
			voteData = await ExtendedVoteData(v, constituentID: const.identifier, group: group)
		case .simplemajority(let v):
			guard !(await v.hasConstituentVoted(const)) && voteStatus == .open else {throw Abort(.unauthorized)}
			voteData = await ExtendedVoteData(v, constituentID: const.identifier, group: group)
		}
		
		return voteData
	}
	
	API.post("postvote", ":voteID", use: postVote)
	func postVote(req: Request) async throws -> [String]{
		// Retrieve contextual information
		let linker = try req.auth.require(GroupConstLinker.self, Abort(.unauthorized))
		let dbGroup = linker.group
		let group = await groupsManager.groupForGroup(dbGroup)
		let const = linker.constituent.asConstituent()
		
		guard
			let voteIDStr = req.parameters.get("voteID"),
			let vote = await group.voteForID(voteIDStr)
		else {
			throw Abort(.notFound) //404
		}
		
		// Checks that the vote is open
		guard await group.statusFor(await vote.id()) == .open else {
			throw Abort(.unauthorized) //401
		}
		
		// Decodes and stores the vote
		let p: ((data: Any?, error: Error)?, [String]?)
		switch vote {
		case .alternative(let v):
			p = await decodeAndStore(group: group, vote: v, constituent: const, req: req)
		case .yesno(let v):
			p = await decodeAndStore(group: group, vote: v, constituent: const, req: req)
		case .simplemajority(let v):
			p = await decodeAndStore(group: group, vote: v, constituent: const, req: req)
		}
		
		if let confirmationStrings = p.1{
			return confirmationStrings
		} else if p.0 != nil {
			throw p.0!.error
		} else {
			assertionFailure("This case should never be reached")
			throw Abort(.internalServerError) //500
		}
	}
}


