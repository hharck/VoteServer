import Fluent
import Vapor
import Foundation
import VoteKit

final class DBGroup: Model, Content {
	static let schema = "Groups"
	
	@ID(key: .id)
	var id: UUID?
	
	@Field(key: "name")
	var name: String
	
	@Field(key: "joinphrase")
	var joinphrase: String
	
	@Timestamp(key: "created", on: .create)
	var creationDate: Date?
	
	@Timestamp(key: "last_access", on: .update)
	var lastAccess: Date?
	
	@Field(key: "settings")
	var settings: GroupSettings
	
	/// Constituents who aren't yet users, but count as verified
	@Children(for: \GroupConstLinker.$group)
	var constituents: [GroupConstLinker]

	@Children(for: \GroupInvite.$group)
	var invite: [GroupInvite]
	
	init(name: String, joinphrase: JoinPhrase, settings: GroupSettings){
		self.name = name
		self.joinphrase = joinphrase
		self.settings = settings
	}
	
	init(){}
}

extension DBGroup: Authenticatable{}

extension DBGroup{
	/// - Warning: Does not save
	func updateUnverifiedSetting(_ newValue: Bool, relatedGroup: Group, db: Database) async throws {
		if !newValue && settings.allowsUnverifiedConstituents {
			let unverified = constituents.filter(\.isCurrentlyIn).filter(\.isNotVerified)
			
			try await relatedGroup.setRemoveUnverifiedConstituents(Set(unverified.asConstituents()))
			
			unverified.forEach { link in
				link.isCurrentlyIn = false
				#warning("Check if they are actually kicked with just the saving of the main")
//				link.save(on: db)
			}
		}
		settings.allowsUnverifiedConstituents = newValue
	}
}
