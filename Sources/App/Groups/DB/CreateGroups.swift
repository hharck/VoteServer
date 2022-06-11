import Fluent

struct CreateDBGroup: Migration {
	func prepare(on database: Database) -> EventLoopFuture<Void> {
		return database.schema(DBGroup.schema)
			.id()
			.field("name", .string, .required)
			.field("joinphrase", .string, .required)
			.field("created", .datetime)
			.field("last_access", .datetime)
			.field("settings", .json, .required)
			.unique(on: "joinphrase")
			.create()
	}

	func revert(on database: Database) -> EventLoopFuture<Void> {
		return database.schema(DBGroup.schema).delete()
	}
}
