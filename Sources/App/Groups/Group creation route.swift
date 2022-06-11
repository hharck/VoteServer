import Vapor
import FluentKit

/// Defines the /create path and its logic
/// - Parameters:
///   - path: The path on which to create groups
func groupCreationRoutes(_ path: RoutesBuilder, groupsManager: GroupsManager) {
	path.get(use: GroupCreatorUI.init)
	path.post(use: createGroup)
	func createGroup(req: Request) async throws -> Response{
		let user = try req.auth.require(DBUser.self)
		// Checks that the user is allowed to create a group
		guard user.mayCreateAGroup() else {
			throw Abort(.notAcceptable)
		}
		
		var groupData: GroupCreatorData?
		do{
			groupData = try req.content.decode(GroupCreatorData.self)
			//Makes groupData non optional for the rest of this scope
			let groupData = groupData!
			
			let groupName = try groupData.getGroupName()
			let settings = GroupSettings(allowsUnverifiedConstituents: groupData.allowsUnverified())
			guard let joinphrase = await groupsManager.createJoinPhrase() else {
				throw Abort(.internalServerError)
			}
			
			let users = try groupData.getEmails()
			
			
			let (invitesNeedingAnEmail, groupID) = try await req.db.transaction { db -> ([String], UUID) in
				var invitesNeedingAnEmail = [String]()
				
				let group = DBGroup(name: groupName, joinphrase: joinphrase, settings: settings)
				try await group.save(on: db)
				
				var hasMeetAdmin = false

				for (em, t) in users {

					let tag: String? = (t == nil || t!.isEmpty) ? nil : t
					
					let email = em.lowercased()
					if email == user.email {
						let linker = GroupConstLinker(isCurrentlyIn: true, isVerified: true, isAdmin: true, tag: tag)
						linker.$group.id = try group.requireID()
						linker.$constituent.id = try user.requireID()
						try await linker.save(on: db)
						hasMeetAdmin = true
					} else if let u = try await DBUser
						.query(on: db)
						.filter(\.$email == email)
						.first() {
						
						let linker = GroupConstLinker(isCurrentlyIn: false, isVerified: true, isAdmin: false, tag: tag)
						
						linker.$group.id = try group.requireID()
						linker.$constituent.id = try u.requireID()
						try await linker.save(on: db)
						
					} else {
						let invite: InvitedUser
						if let i = try await InvitedUser
							.query(on: db)
							.filter(\.$email == email)
							.first() {
							
							invite = i
						} else {
							invite = InvitedUser.create(email: email)
							try await invite.create(on: db)
							invitesNeedingAnEmail.append(email)
						}
						
						
						let d = GroupInvite()
						d.$group.id = try group.requireID()
						d.$invite.id = try invite.requireID()
						d.tag = tag
						try await d.save(on: db)
					}
					
				}
				
				guard hasMeetAdmin else {
					throw GroupCreationError.adminMustBeIncluded
				}
				
				
				try await group.save(on: db)
				return (invitesNeedingAnEmail, group.id!)
			}
			// No error occurred, therefore a group must have been created, redirecting the user to the admin page
			return req.redirect(to: .admin, for: groupID)
		} catch {
			return try await GroupCreatorUI(errorString: error.asString(), groupData).encodeResponse(for: req)
		}
		
	}
}
