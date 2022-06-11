import Fluent

struct CreateChats: Migration {
	func prepare(on database: Database) -> EventLoopFuture<Void> {
		return database.schema(Chats.schema)
			.id()
			.field("group_and_sender", .uuid, .required, .references(GroupConstLinker.schema, .id))
			.field("message", .string, .required)
			.field("timestamp", .datetime)
			.field("systems_message", .bool, .required, .sql(.default(false)))
			.create()
	}

	func revert(on database: Database) -> EventLoopFuture<Void> {
		return database.schema(Chats.schema).delete()
	}
}
