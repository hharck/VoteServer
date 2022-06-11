import Vapor
import FluentKit
import VoteKit

// Many to many relationship
final class GroupInvite: Model, Content {
	static let schema = "GroupInvitedUser"
	@ID(key: .id)
	var id: UUID?
	
	@Parent(key: "group")
	var group: DBGroup
	
	@Parent(key: "invite")
	var invite: InvitedUser
	
	@Field(key: "tag")
	var tag: String?
	
	init() {}
}
