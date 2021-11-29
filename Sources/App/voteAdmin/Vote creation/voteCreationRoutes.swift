import Vapor
import AltVoteKit
func voteCreationRoutes(_ app: Application, groupsManager: GroupsManager) throws {
	app.get("createvote") { req async throws -> Response in
		guard
			let sessionID = req.session.authenticated(AdminSession.self),
			let _ = await groupsManager.groupForSession(sessionID)
		else {
			return req.redirect(to: .create)
		}
		return try await VoteUICreator().encodeResponse(for: req)
	}
	
	app.post("createvote") { req async throws -> Response in
		guard
			let sessionID = req.session.authenticated(AdminSession.self),
			let group = await groupsManager.groupForSession(sessionID)
		else {
			return req.redirect(to: .create)
		}
		
		var voteHTTPData: VoteCreationReceivedData? = nil
		do {
			
			voteHTTPData = try req.content.decode(VoteCreationReceivedData.self)
			
			// Since it voteHTTPData was just set it'll in this scope be treated as not being an optional
			let voteHTTPData = voteHTTPData!
			
			let tieBreakers: [TieBreaker] = [.dropAll, .removeRandom, .keepRandom]
			
			
			
			// Validates the data and generates a Vote object
			let vote = Vote(name: try voteHTTPData.getTitle(), options: try voteHTTPData.getOptions(), votes: [], validators: voteHTTPData.getValidators(), constituents: await group.verifiedConstituents.union(await group.unVerifiedConstituents), tieBreakingRules: tieBreakers)
			
			
			await group.addVoteToGroup(vote: vote)
			return req.redirect(to: .voteadmin)
			
		} catch {
			
			return try await VoteUICreator(errorString: error.asString(), voteHTTPData).encodeResponse(for: req)
		}
		
	}
}

