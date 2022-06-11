import Vapor
import VoteKit
import FluentKit

func plazaRoutes(_ path: RoutesBuilder, groupsManager: GroupsManager) {
	
	
	
	
	
	
//	app.get("join", use: getJoin)
//	func getJoin(req: Request) async -> GroupJoinUI {
//		let showRedirectToPlaza = await groupsManager.groupAndVoterForReq(req: req) != nil
//		return GroupJoinUI(title: "Join", showRedirectToPlaza: showRedirectToPlaza)
//	}
//	
//	// Prefills the field with the joinphrase and redirects invalid joinphrases
//	app.get("join", ":joinphrase", use: joinWithPhrase)
//	func joinWithPhrase(req: Request) async throws -> GroupJoinUI{
//		guard
//			let jf = req.parameters.get("joinphrase"),
//			let group = await groupsManager.groupForJoinPhrase(jf)
//		else {
//			throw Redirect(.join)
//		}
//		let showRedirectToPlaza = await groupsManager.groupAndVoterForReq(req: req) != nil
//		return GroupJoinUI(title: group.name, joinPhrase: jf, showRedirectToPlaza: showRedirectToPlaza)
//	}
//	
//	app.post("join", use: postJoin)
//	app.post("join", ":joinphrase", use: postJoin)
//	func postJoin(req: Request) async throws -> Response{
//		try await joinGroup(req, groupsManager, forAPI: false)
//	}
//	
	// Shows a plaza containing votes available for the user and a chatfield
	path.get(use: getPlaza)
	func getPlaza(req: Request) async throws -> PlazaUI {
		let linker = try req.auth.require(GroupConstLinker.self, Redirect(.join))
		let user = try req.auth.require(DBUser.self)
		let dbGroup = try req.auth.require(DBGroup.self)
		let group = await groupsManager.groupForGroup(dbGroup)
		
		
		return await PlazaUI(linker: linker, dbGroup: dbGroup, group: group, user: user)
	}
    
	path.post(use: postPlaza)
	func postPlaza(req: Request) async throws -> PlazaUI{
		let linker = try req.auth.require(GroupConstLinker.self, Redirect(.join))
		let dbGroup = linker.group
		let group = await groupsManager.groupForGroup(dbGroup)
		let user = try req.auth.require(DBUser.self)
		if
			dbGroup.settings.constituentsCanSelfResetVotes,
			let deleteID = (try? req.content.decode([String:String].self))?["deleteId"],
			let voteID = UUID(deleteID),
			let vote = await group.voteForID(voteID),
			await group.statusFor(voteID) == .open
		{
			await group.singleVoteReset(vote: vote, linker: linker)
		}
		
		return await PlazaUI(linker: linker, dbGroup: dbGroup, group: group, user: user)
	}
}


enum joinGroupErrors: ErrorString, Equatable{
	case userIDIsInvalid
	case userIsNotAllowedIn
	case noGroupForJF(JoinPhrase)
	case constituentIsAlreadyIn
	
	func errorString() -> String {
		switch self {
		case .userIDIsInvalid:
			return "Invalid userID"
		case .userIsNotAllowedIn:
			return "You're not allowed to access this group"
		case .noGroupForJF(let joinPhrase):
			return "No group was found for '\(joinPhrase.htmlEscaped())'"
		case .constituentIsAlreadyIn:
			return "This user has already joined, if you think this is an error ask the admin to reset your access"
		}
	}
}



//Used by the HTML client and the API to join groups
func joinGroup(_ req: Request, _ groupsManager: GroupsManager, forAPI: Bool) async throws -> Response{
fatalError()
	
	#warning("Needs to be reimplemented")
	//	struct JoinGroupData: Codable{
//		var userID: String
//		var joinPhrase: String
//	}
//
//	guard let content = try? req.content.decode(JoinGroupData.self) else{
//		throw "Invalid request"
//	}
//
//
//	let userID = content.userID.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
//	let joinPhrase = content.joinPhrase.trimmingCharacters(in: .whitespacesAndNewlines)
//
//	var groupName: String?
//	do{
//		guard !userID.isEmpty else {
//			throw joinGroupErrors.userIDIsInvalid
//		}
//
//        // Checks that the user id does not contain a comma or a semicolon
//		guard !userID.contains(","), !userID.contains(";"), userID.count <= Config.maxNameLength, !userID.contains("admin") else {
//            throw joinGroupErrors.userIDIsInvalid
//        }
//
//		guard let group = await groupsManager.groupForJoinPhrase(joinPhrase, req.db) else {
//			throw joinGroupErrors.noGroupForJF(joinPhrase)
//		}
//
//		groupName = group.name
//
//
//		// Creates a constituent object for the requesting client
//		let const: Constituent
//		if let c = await group.verifiedConstituent(for: userID){
//			const = c
//		} else {
//			//Checks if verification is required
//            guard await group.settings.allowsUnverifiedConstituents else {
//				throw joinGroupErrors.userIsNotAllowedIn
//			}
//
//			const = Constituent(stringLiteral: userID)
//		}
//
//
//		let constituentID = UUID()
//		// Adds the constituent
//		guard await group.joinConstituent(const, for: constituentID) else {
//			throw joinGroupErrors.constituentIsAlreadyIn
//		}
//
//
//        if forAPI{
//            guard let data = await group.getExchangeData(for: userID) else {
//                throw Abort(.internalServerError)
//            }
//			req.session.authenticate(APISession(sessionID: constituentID))
//			req.session.authenticate(await group.groupSession)
//
//            return Response(body: .init(data: try JSONEncoder().encode(data)))
//        } else{
//            // Adds the group and constituent key to the user's session
//            req.session.authenticate(VoterSession(sessionID: constituentID))
//			req.session.authenticate(await group.groupSession)
//
//            return req.redirect(to: .plaza)
//        }
//
//	} catch {
//        if forAPI{
//            if let er = error as? joinGroupErrors {
//                if er == .constituentIsAlreadyIn{
//                    throw Abort(.alreadyReported)
//                }
//            }
//           throw Abort(.unauthorized)
//
//        } else {
//            let showRedirectToPlaza = await groupsManager.groupAndVoterForReq(req: req) != nil
//
//            return try await GroupJoinUI(title: groupName ?? "Join", joinPhrase: joinPhrase, userID: userID, errorString: error.asString(), showRedirectToPlaza: showRedirectToPlaza).encodeResponse(for: req)
//        }
//	}
}
