import Vapor
import VoteExchangeFormat
import FluentKit

func APIRoutes(_ API: RoutesBuilder, groupsManager: GroupsManager){
	ChatRoutes(API.grouped("chat"), groupsManager: groupsManager)
	
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
		
		let voteStatus = await group.statusFor(await vote.id)
		guard !(await vote.hasConstituentVoted(const)) && voteStatus == .open else {throw Abort(.unauthorized)}
		return await ExtendedVoteData(vote, constituentID: const.identifier, group: group)
	}
	
	API.post("postvote", ":voteID", use: postVote)
	func postVote(req: Request) async throws -> [String] {
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
		guard await group.statusFor(await vote.id) == .open else {
			throw Abort(.unauthorized) //401
		}
		
		// Fixes any DVoteProtocol not being a DVoteProtocol
		func wrapper(vote: some DVoteProtocol) async throws -> [String] {
			// Decodes and stores the vote
			let p = await decodeAndStore(group: group, vote: vote, constituent: const, req: req)
			
			if let confirmationStrings = p.1{
				return confirmationStrings
			} else if p.0 != nil {
				throw p.0!.error
			} else {
				assertionFailure("This case should never be reached")
				throw Abort(.internalServerError) //500
			}
			
		}
		return try await wrapper(vote: vote)
	}
}
