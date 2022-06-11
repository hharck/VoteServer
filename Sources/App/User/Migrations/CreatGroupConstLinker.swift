import Fluent

struct CreateGroupConstLinker: Migration {
	func prepare(on database: Database) -> EventLoopFuture<Void> {
		return database.schema(GroupConstLinker.schema)
			.id()
			.field("group", .uuid, .required, .references(DBGroup.schema, "id"))
			.field("constituent", .uuid, .required, .references(DBUser.schema, "id"))
			.field("join_time", .datetime)
			.field("is_currently_in", .bool, .required)
			.field("is_verified", .bool, .required)
			.field("is_admin", .bool, .required)
			.field("is_banned", .bool, .required, .sql(.default(false)))
			.field("tag", .string)
			.unique(on: "group", "constituent")
			.create()
	}

	func revert(on database: Database) -> EventLoopFuture<Void> {
		return database.schema(GroupConstLinker.schema).delete()
	}
}
