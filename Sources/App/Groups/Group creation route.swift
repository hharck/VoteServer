import Vapor
/// Defines the /create path and its logic
func groupCreationRoutes(_ app: Application, groupsManager: GroupsManager) {
    app.get("create", use: GroupCreatorUI.init)
    app.post("create", use: createGroup)
    @Sendable func createGroup(req: Request) async -> ResponseOrRedirect<GroupCreatorUI> {
        do {
            let groupData = try req.content.decode(GroupCreatorData.self)
            let session = AdminSession()

            do {
                // Saves the group
                try await groupsManager.createGroup(
                    session: session.sessionID,
                    db: req.db,
                    name: try groupData.getGroupName(),
                    constituents: try groupData.getConstituents(),
                    pwdigest: try groupData.getHashedPassword(for: req),
                    allowsUnverified: groupData.allowsUnverified
                )
            } catch {
                return .response(GroupCreatorUI(errorString: error.asString(), groupData))
            }

            // Registers the session with the client
            req.session.authenticate(session)
            return .redirect(.admin)
        } catch {
            return .response(GroupCreatorUI(errorString: error.asString(), nil))
        }
    }
}
