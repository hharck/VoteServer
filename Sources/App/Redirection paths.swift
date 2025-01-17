import Vapor
import VoteExchangeFormat

/// Defines paths often used for redirection
enum RedirectionPaths{
	case create
    case createvote(VoteTypes.StringStub)
	case voteadmin(String?)
    case results(String)
    case admin
	case join
	case plaza
	case constituents
	case login
    case API(APIPath: APIPaths)
    
	func stringValue() -> String{
		switch self {
		case .create: "create"
		case .createvote(let string): "createvote/" + string.rawValue
		case .voteadmin(let id):
			if let id {
                "voteadmin/\(id)"
			} else {
                "voteadmin"
			}
		case .results(let id): "results/\(id)"
        case .admin: "admin"
        case .join: "join"
		case .plaza: "plaza"
		case .constituents: "admin/constituents"
		case .login: "login"
        case .API(let APIPath): "api/v1/" + APIPath.relativeStringValue()
		}
	}
}

extension Request{
    func redirect(to location: RedirectionPaths, type: Vapor.Redirect = .normal) -> Response {
        redirect(to: "/" + location.stringValue() + "/", redirectType: type)
    }
}

extension RedirectionPaths: AsyncResponseEncodable, ResponseEncodable{
    func encodeResponse(for req: Request) throws -> Response {
        req.redirect(to: self)
    }

    func encodeResponse(for req: Request) -> EventLoopFuture<Response> {
        req.eventLoop.makeSucceededFuture(req.redirect(to: self))
    }
}

// Enables creating routes directly for redirection
extension RoutesBuilder {
	@discardableResult
	func redirectGet(_ path: PathComponent..., to: RedirectionPaths) -> Route{
		return self.on(.GET, path){ req in
			req.redirect(to: to)
		}
	}
}
