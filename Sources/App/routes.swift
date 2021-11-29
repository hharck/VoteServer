import Vapor
import AsyncHTTPClient
import AltVoteKit

func routes(_ app: Application) throws {
	let groupsManager = GroupsManager()

	app.get { req in
		req.redirect(to: .create)
	}
	
	app.get("version"){req async in
		return "Server version: 2.0.2\nAltVoteKit version \(AltVoteKitVersion)"
	}

	try groupCreationRoutes(app, groupsManager: groupsManager)
	try voteCreationRoutes(app, groupsManager: groupsManager)
	try votingRoutes(app, groupsManager: groupsManager)
	try ResultRoutes(app, groupsManager: groupsManager)
	try adminRoutes(app, groupsManager: groupsManager)
	try groupJoinRoutes(app, groupsManager: groupsManager)
}
