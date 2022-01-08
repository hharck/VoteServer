import Vapor
import VoteKit
import Foundation
func groupJoinRoutes(_ app: Application, groupsManager: GroupsManager) throws {
	app.get("join"){_ in
		GroupJoinUI(title: "Join")
	}
	
	app.get("join", ":joinphrase"){req async throws -> Response in
		guard
			let jf = req.parameters.get("joinphrase"),
			let group = await groupsManager.groupForJoinPhrase(jf)
		else {
			return req.redirect(to: .join)
		}
		return try await GroupJoinUI(title: group.name, joinPhrase: jf).encodeResponse(for: req)
	}
	
	app.post("join") { req async throws in
		try await joinGroup(req, groupsManager)
	}
	
	app.post("join", ":joinphrase") { req async throws in
		try await joinGroup(req, groupsManager)
	}
	
	
	app.get("plaza"){req async -> Response in
		guard let (group, constituent) = await groupsManager.groupAndVoterForReq(req: req) else {
			return req.redirect(to: .join)
		}
		
		let controller = await PlazaUI(constituent: constituent, group: group)
		
		return (try? await controller.encodeResponse(for: req)) ?? req.redirect(to: .join)
		
	}
}


enum joinGroupErrors: ErrorString{
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




func joinGroup(_ req: Request, _ groupsManager: GroupsManager) async throws -> Response{
	struct JoinGroupData: Codable{
		var userID: String
		var joinPhrase: String
	}

	
	guard let content = try? req.content.decode(JoinGroupData.self) else{
		throw "Invalid request"
	}
	
	
	let userID = content.userID.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
	let joinPhrase = content.joinPhrase.trimmingCharacters(in: .whitespacesAndNewlines)
	
	var groupName: String?
	do{
		guard !userID.isEmpty else {
			throw joinGroupErrors.userIDIsInvalid
		}
        
        // Checks that the user id does not contain a comma or a semicolon
        guard !userID.contains(","), !userID.contains(";") else {
            throw joinGroupErrors.userIDIsInvalid
        }
		
		guard let group = await groupsManager.groupForJoinPhrase(joinPhrase) else {
			throw joinGroupErrors.noGroupForJF(joinPhrase)
		}
		
		groupName = group.name
		
		
		// Creates a constituent object for the requesting client
		let const: Constituent
		if let c = await group.verifiedConstituent(for: userID){
			const = c
		} else {
			//Checks if verification is required
			guard await group.allowsUnverifiedConstituents else {
				throw joinGroupErrors.userIsNotAllowedIn
			}
			
			const = Constituent(stringLiteral: userID)
		}
		
		
		let constituentID = UUID()
		// Adds the constituent
		guard await group.joinConstituent(const, for: constituentID) else {
			throw joinGroupErrors.constituentIsAlreadyIn
		}
		
		// Adds the group and constituent key to the user's session
		req.session.authenticate(VoterSession(sessionID: constituentID))
		req.session.authenticate(await group.groupSession)
		
	} catch {
		return try await GroupJoinUI(title: groupName ?? "Join", joinPhrase: joinPhrase, userID: userID, errorString: error.asString()).encodeResponse(for: req)
	}
	return req.redirect(to: .plaza)
	
}
