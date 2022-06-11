import Fluent
import Vapor
import Foundation
import VoteKit

final class DBUser: Model, Content {
	static let schema = "Constituents"
	
	@ID(key: .id)
	var id: UUID?
	
	@Field(key: "name")
	var name: String
	
	@Field(key: "username")
	var username: String
	
	@Field(key: "email")
	var email: String
	
	@Field(key: "email_is_verified")
	var emailIsVerfied: Bool
	
	@Field(key: "email_hash")
	var emailHash: String
	
	@Field(key: "password_digest")
	var passwordDigest: String?
	
	@Children(for: \GroupConstLinker.$constituent)
	var groups: [GroupConstLinker]
	

	init(name: String, username: String, email: String, passwordDigest: String?){
		self.name = name
		self.username = username
		self.email = email
		self.emailHash = getHashFor(email)
		self.passwordDigest = passwordDigest
	}
	
	init(){}
}

extension DBUser{
	func asConstituent(tag: String? = nil) -> Constituent{
		Constituent(name: self.name, identifier: self.username, tag: tag, email: self.email)
	}
	
	func mayCreateAGroup() -> Bool{
		return true //self.emailIsVerfied
	}
}

extension DBUser: SessionAuthenticatable{
	/// Session identifier type.
	typealias SessionID = UUID

	/// Unique session identifier.
	var sessionID: SessionID {
		guard let id = self.id else {
			assertionFailure()
			return UUID()
		}
		return id
	}
}

struct UserAuthenticator: AsyncSessionAuthenticator{
	typealias User = DBUser
	func authenticate(sessionID: UUID, for req: Request) async throws {
		if let user = try await User.find(sessionID, on: req.db)
		{
			req.auth.login(user)
		}
	}
}
