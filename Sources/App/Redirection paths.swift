import Vapor
import VoteExchangeFormat
import Foundation


protocol RedirectionPath{
	func stringValue() -> String
}
/// Defines paths often used for redirection
enum RedirectionPaths: RedirectionPath{
	case create
	case join
	case login
	case signup
	case user
    case API(APIPath: APIPaths)
    
	func stringValue() -> String{
		switch self {
		case .create:
			return "create"
        case .join:
			return "join"
		case .login:
			return "login"
		case .signup:
			return "signup"
		case .user:
			return "user"
        case .API(let APIPath):
            return "api/v1/" + APIPath.relativeStringValue()
		}
	}
}

enum GroupSpecificPaths: RedirectionPath{
	case createvote(VoteTypes.StringStub)
	case voteadmin(String?)
	case results(String)
	case admin
	case plaza
	case constituents
	
	func stringValue() -> String{
		switch self {
		case .createvote(let string):
			return "admin/createvote/" + string.rawValue
		case .voteadmin(let id):
			if id == nil {
				return "voteadmin"
			} else {
				return "voteadmin/\(id!)"
			}
		case .results(let id):
			return "results/\(id)"
		case .admin:
			return "admin"
		case .plaza:
			return ""
		case .constituents:
			return "admin/constituents"
		}
	}
}


extension Request{
	func redirect(to location: RedirectionPaths, type: RedirectType = .normal) -> Response {
		self.redirect(to: "/" + location.stringValue() + "/", type: type)
	}
	
	func redirect(to location: GroupSpecificPaths, type: RedirectType = .normal, for groupID: UUID? = nil) -> Response {
		let gid: UUID
		if groupID == nil{
			if let gi = self.auth.get(DBGroup.self)?.id{
				gid = gi
			} else {
				assertionFailure("Used a group redirect without having an authenticated group or passing an id")
				return self.redirect(to: "")
			}
		} else {
			gid = groupID!
		}
		
		return self.redirect(to: "/group/\(gid.uuidString)/" + location.stringValue() + "/", type: type)
	}
	
	func _redirect(to location: RedirectionPath, type: RedirectType = .normal) -> Response{
		if let rp = location as? RedirectionPaths {
			return self.redirect(to: rp)
		} else if let gp = location as? GroupSpecificPaths {
			return self.redirect(to: gp)
		} else {
			fatalError()
		}
	}
}

extension RedirectionPaths: AsyncResponseEncodable, ResponseEncodable{
	func encodeResponse(for req: Request) async throws -> Response {
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
	
	@discardableResult
	func redirectGet(_ path: PathComponent..., to: GroupSpecificPaths) -> Route{
		return self.on(.GET, path){ req -> Response in
			let id = try req.auth.require(DBGroup.self, Redirect(.user)).requireID()
			return req.redirect(to: to, for: id)
		}
	}
}

/*
 import Vapor
 import VoteExchangeFormat

 /// Defines paths often used for redirection
 enum RedirectionPaths{
	 case create
	 case createvote(VoteTypes.StringStub)
	 case voteadmin(group: String, vote: String)
	 case results(group: String, vote: String)
	 case admin(group: String)
	 case constituents(group: String)
	 
	 case join
	 case plaza(group: String)
	 
	 case login
	 case signup
	 case user
	 case API(APIPath: APIPaths)
	 
	 func stringValue() -> String{
		 switch self {
		 case .create:
			 return "create"
		 case .createvote(let string):
			 return "createvote/" + string.rawValue
		 case .voteadmin(group: let group, vote: let vote):
			 return "group/\(group)/voteadmin/\(vote)"
		 case .results(group: let group, vote: let vote):
			 return "group/\(group)/results/\(vote)"
		 case .admin(let group):
			 return "group/\(group)"
		 case .join:
			 return "join"
		 case .plaza:
			 return "plaza"
		 case .constituents:
			 return "admin/constituents"
		 case .login:
			 return "login"
		 case .signup:
			 return "signup"
		 case .user:
			 return "user"
		 case .API(let APIPath):
			 return "api/v1/" + APIPath.relativeStringValue()
		 }
	 }
 }

 extension Request{
	 func redirect(to location: RedirectionPaths, type: RedirectType = .normal) -> Response {
		 self.redirect(to: "/" + location.stringValue() + "/", type: type)
	 }
 }

 extension RedirectionPaths: AsyncResponseEncodable, ResponseEncodable{
	 func encodeResponse(for req: Request) async throws -> Response {
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

 */
