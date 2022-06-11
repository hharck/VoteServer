import Fluent

struct CreateUsers: Migration {
	func prepare(on database: Database) -> EventLoopFuture<Void> {
		return database.schema(DBUser.schema)
			.id()
			.field("name", .string, .required)
			.field("username", .string, .required)
			.field("email", .string, .required)
			.field("email_is_verified", .bool, .sql(.default(false)))
			.field("email_hash", .string, .required)
			.field("password_digest", .string)
			.unique(on: "username")
			.unique(on: "email")
			.unique(on: "email_hash")
			.create()
	}

	func revert(on database: Database) -> EventLoopFuture<Void> {
		return database.schema(DBUser.schema).delete()
	}
}
