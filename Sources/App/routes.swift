import Vapor
import AltVoteKit

/// Calls all route creaters, which inturn registers and handles the available paths in the app
func routes(_ app: Application, groupsManager: GroupsManager) throws {
	app.redirectGet(to: .user)
	let path = app.grouped(UserAuthenticator())
	userRoutes(path)
	#warning("Tilføj Guard middleware til alle ruter")
	let signedIn = path.grouped(UserAuthenticator(), DBUser.guardMiddleware())//.grouped(DBUser.guardMiddleware())
	let inGroup = signedIn.grouped("group", ":groupID").grouped(GroupAuthMiddleware())
	
	
	let requiresGroupAdmin = inGroup.grouped(EnsureGroupAdmin())
	
	groupCreationRoutes(path.grouped(UserAuthenticator()).grouped("create"), groupsManager: groupsManager)
	
	plazaRoutes(inGroup, groupsManager: groupsManager)
	votingRoutes(inGroup.grouped("vote", ":voteID"), groupsManager: groupsManager)
	
    ResultRoutes(requiresGroupAdmin, groupsManager: groupsManager)
    adminRoutes(requiresGroupAdmin, groupsManager: groupsManager)
    APIRoutes(signedIn.grouped("api", "v1"), groupsManager: groupsManager)
}
