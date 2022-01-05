import Vapor
import AltVoteKit

/// Calls all route creaters, which inturn registers and handles the available paths in the app
func routes(_ app: Application) throws {
	let groupsManager = GroupsManager()

	app.get { req in
		req.redirect(to: .create)
	}

	try groupCreationRoutes(app, groupsManager: groupsManager)
	try voteCreationRoutes(app, groupsManager: groupsManager)
	try votingRoutes(app, groupsManager: groupsManager)
	try ResultRoutes(app, groupsManager: groupsManager)
	try adminRoutes(app, groupsManager: groupsManager)
	try groupJoinRoutes(app, groupsManager: groupsManager)
}
