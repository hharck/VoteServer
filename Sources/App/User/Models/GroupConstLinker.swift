import Vapor
import FluentKit
import VoteKit

// Many to many relationship
final class GroupConstLinker: Model, Content {
	static let schema = "GroupConstLinker"
	@ID(key: .id)
	var id: UUID?
	
	@Parent(key: "group")
	var group: DBGroup
	
	@Parent(key: "constituent")
	var constituent: DBUser
	
	@Timestamp(key: "join_time", on: .create)
	var firstJoinedAt: Date?
	
	/// User has accepted joining the group
	@Field(key: "is_currently_in")
	var isCurrentlyIn: Bool
	
	/// User is part of the default "verified" users
	@Field(key: "is_verified")
	var isVerified: Bool

	/// User has admin privileges
	@Field(key: "is_admin")
	var isAdmin: Bool
	
	/// User has been banned from entering the group
	@Field(key: "is_banned")
	var isBanned: Bool

	/// User has accepted joining group
	@Field(key: "tag")
	var tag: String?
	
	@Children(for: \Chats.$groupAndSender)
	var chats: [Chats]
	
	init(isCurrentlyIn: Bool, isVerified: Bool, isAdmin: Bool, tag: String?){
		self.isCurrentlyIn = isCurrentlyIn
		self.isVerified = isVerified
		self.isAdmin = isAdmin
		self.tag = tag
	}
	
	init(){}
}

extension GroupConstLinker: Authenticatable{}

extension GroupConstLinker{
	var isNotVerified: Bool {
		!isVerified
	}
	
	var asConstituent: Constituent {
		try! self.joined(DBUser.self).asConstituent(tag: self.tag)
	}
}


extension Array where Element == GroupConstLinker{
	func asConstituents() throws -> [Constituent] {
		try self.map{try $0.joined(DBUser.self).asConstituent()}
	}
}
