import Vapor

/// Redirects all 401 unauthorized errors to the login page
struct RedirectUnauth: AsyncMiddleware {
	func respond(to req: Request, chainingTo next: AsyncResponder) async throws -> Response {
		do {
			return try await next.respond(to: req)
		} catch let error as AbortError{
			if error.status == .unauthorized {
				return req.redirect(to: .login)
			} else {
				throw error
			}
		}
	}
}

