import Vapor
import Fluent

struct EnsureGroupAdmin: AsyncMiddleware {
	func respond(to req: Request, chainingTo next: AsyncResponder) async throws -> Response {
		guard
			let linker = req.auth.get(GroupConstLinker.self)
		else {
			assertionFailure("This middleware should not be called if user and group hasn't been set")
			throw Abort(.internalServerError)
		}
		
		guard linker.isAdmin else {
			throw Abort(.unauthorized)
		}
		
		return try await next.respond(to: req)
	}
}


struct GroupIdKey: StorageKey{
	typealias Value = UUID
}



struct GroupAuthMiddleware: AsyncRequestAuthenticator {
	func authenticate(request req: Request) async throws {
		guard
			let groupIDStr = req.parameters.get("groupID"),
			let groupID = UUID(uuidString: groupIDStr)
		else {
			throw Abort(.internalServerError)
		}
		
		// Fetches the group from DB
		guard let group = try await DBGroup.find(groupID, on: req.db) else {
			throw Abort(.notFound)
		}
		// Ensures constituents are available
		try await group.$constituents.load(on: req.db)
		
		// Finds the user within the groups constituents
		let userID = try req.auth.require(DBUser.self).requireID()
		
		// Authenticates a linker if the user is already in
		if !self.ignoreLinker {
			guard let linker = try await group
				.$constituents
				.query(on: req.db)
				.filter(\.$constituent.$id == userID)
				.filter(\.$isCurrentlyIn == true)
				.join(parent: \.$group)
				.join(parent: \.$constituent)
				.first()
			else {
				throw Abort(.unauthorized)
			}
			req.auth.login(linker)
		}
		req.auth.login(group)
	}
	
	let ignoreLinker: Bool
	
	init(ignoreLinker: Bool = false){
		self.ignoreLinker = ignoreLinker
	}
}
