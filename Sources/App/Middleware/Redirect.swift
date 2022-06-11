import Vapor

// Intercepts RedirectError and redirects the client to the given page
struct RedirectErrorHandler: AsyncMiddleware {
	func respond(to req: Request, chainingTo next: AsyncResponder) async throws -> Response {
		do {
			return try await next.respond(to: req)
		} catch let error as Redirect{
			return req._redirect(to: error.path)
		}
	}
}

struct Redirect: Error{
	let path: RedirectionPath
	init(_ path: RedirectionPaths){
		self.path = path
	}
	
	init(_ path: GroupSpecificPaths){
		self.path = path
	}
}
