import Fluent

struct CreateInvitedUser: Migration {
	func prepare(on database: Database) -> EventLoopFuture<Void> {
		return database.schema(InvitedUser.schema)
			.id()
			.field("email", .string, .required)
			.field("email_hash", .string, .required)
			.field("create_token", .string, .required)
			.field("created", .datetime)
			.field("expires", .datetime, .required)
			.unique(on: "email")
			.unique(on: "create_token")
			.create()
	}

	func revert(on database: Database) -> EventLoopFuture<Void> {
		return database.schema(InvitedUser.schema).delete()
	}
}
