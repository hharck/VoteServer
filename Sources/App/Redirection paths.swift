import Vapor

/// Defines paths often used for redirection
enum redirectionPaths{
	case create
	case createvote
	case results(String)
	case voteadmin(String?)
	static var voteadmin: Self {.voteadmin(nil)}
	case join
	case plaza
	case constituents
	case login
	
	func stringValue() -> String{
		switch self {
		case .create:
			return "create"
		case .createvote:
			return "createvote"
		case .voteadmin(let id):
			if id == nil {
				return "voteadmin"
			} else {
				return "voteadmin/\(id!)"
			}
		case .results(let id):
			return "results/\(id)"
		case .join:
			return "join"
		case .plaza:
			return "plaza"
		case .constituents:
			return "voteadmin/constituents"
		case .login:
			return "login"
		}
	}
}

extension Request{
	func redirect(to location: redirectionPaths, type: RedirectType = .normal) -> Response {
		self.redirect(to: "/" + location.stringValue() + "/", type: type)
	}
}

extension redirectionPaths: AsyncResponseEncodable, ResponseEncodable{
	func encodeResponse(for req: Request) async throws -> Response {
		req.redirect(to: self)
	}
	
	func encodeResponse(for req: Request) -> EventLoopFuture<Response> {
		req.eventLoop.makeSucceededFuture(req.redirect(to: self))
	}
}
