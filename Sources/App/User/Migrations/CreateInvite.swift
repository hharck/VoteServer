import Fluent

struct CreateInvite: Migration {
	func prepare(on database: Database) -> EventLoopFuture<Void> {
		return database.schema(GroupInvite.schema)
			.id()
			.field("tag", .string)
			.field("group", .uuid, .required, .references(DBGroup.schema, .id))
			.field("invite", .uuid, .required, .references(InvitedUser.schema, .id))
			.unique(on: "group", "invite")
			.create()
	}

	func revert(on database: Database) -> EventLoopFuture<Void> {
		return database.schema(GroupInvite.schema).delete()
	}
}
