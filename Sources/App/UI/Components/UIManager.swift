import Vapor
import Foundation
protocol UIManager: Codable, AsyncResponseEncodable, ResponseEncodable{
	/// The title of the page
	var title: String {get}
	
	/// Errors to be shown
	var errorString: String? {get}
	
	/// The buttons to be shown on the top row
	var buttons: [UIButton] {get}
	
	/// Name of the corresponding leaf template
	static var template: String {get}
	
	func render(for req: Request) async throws -> View
	func render(for req: Request) async throws -> Response

	func encodeResponse(for req: Request) async throws -> Response
	
	var generalInformation: HeaderInformation! {get set}
}



extension UIManager{
	var buttons: [UIButton] {[]}
	func withHeader(for req: Request) -> Self{
		var s = self
		s.generalInformation = HeaderInformation(req: req)
		return s
	}
	
	func render(for req: Request) async throws -> View{
		return try await req.view.render(Self.template, self.withHeader(for: req))
	}
	
	func render(for req: Request) async throws -> Response{
		let view: View = try await self.render(for: req)
		return try await view.encodeResponse(for: req)
	}

	func encodeResponse(for req: Request) async throws -> Response {
		try await self.render(for: req)
	}
	
	func encodeResponse(for req: Request) -> EventLoopFuture<Response>{
		return req.view.render(Self.template, self.withHeader(for: req)).encodeResponse(for: req)
	}
}

struct HeaderInformation: Codable{
	let groupID: UUID?
	let isSignedIn: Bool
	let isAdmin: Bool
	
	init(req: Request){
		let group = req.auth.get(DBGroup.self)
		self.groupID = group?.id
		self.isSignedIn = req.auth.has(DBUser.self)
		self.isAdmin = req.auth.get(GroupConstLinker.self)?.isAdmin ?? false
	}
	
	enum CodingKeys: CodingKey{
		case groupID, isSignedIn, isAdmin
	}
}
