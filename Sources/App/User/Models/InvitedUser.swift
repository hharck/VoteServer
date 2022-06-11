import FluentKit
import Vapor

final class InvitedUser: Model, Content {
	static let schema = "invited_users"
	
	@ID(key: .id)
	var id: UUID?
	
	@Field(key: "email")
	var email: String
	
	@Field(key: "email_hash")
	var emailHash: String
	
	@Field(key: "create_token")
	var createToken: String
	
	@Timestamp(key: "created", on: .create)
	var created: Date?
	
	@Timestamp(key: "expires", on: .none)
	var expires: Date?
	
	
	static func create(email: String) -> Self{
		let token = joinPhraseGenerator(chars: 30)
		return Self.init(email: email, token: token)
	}
	
	private init(email: String, token: String, expiresOn: Date = Date().addingTimeInterval(3 * 24 * 60 * 60)){
		self.email = email
		self.emailHash = getHashFor(email)
		self.createToken = token
		self.expires = expiresOn
	}
	
	init(){}
}
