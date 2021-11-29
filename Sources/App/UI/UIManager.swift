import Vapor
protocol UIManager: Codable, AsyncResponseEncodable{
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
}



extension UIManager{
	var buttons: [UIButton] {[]}
	
	func render(for req: Request) async throws -> View{
		try await req.view.render(Self.template, self)
	}
	
	func render(for req: Request) async throws -> Response{
		let view: View = try await self.render(for: req)
		return try await view.encodeResponse(for: req)
	}

	func encodeResponse(for req: Request) async throws -> Response {
		try await self.render(for: req)
	}
}


protocol UITableManager: UIManager{
	associatedtype rowType: Codable
	var rows: [rowType] {get}
	var tableHeaders: [String] {get}

}

struct UIButton: Codable{
	internal init(uri: String, text: String, color: ButtonColors, lockable: Bool = false) {
		self.uri = uri
		self.text = text
		self.color = color
		self.lockable = lockable
	}
	
	internal init(uri: redirectionPaths, text: String, color: ButtonColors, lockable: Bool = false) {
		self.init(uri: "/" + uri.stringValue() + "/", text: text, color: color, lockable: lockable)
	}
	
	let uri: String
	let text: String
	let color: ButtonColors
	var lockable: Bool
	
	enum ButtonColors: String, Codable{
		case blue, green, red, grey
	}
	
	//MARK: Default buttons
	static var reload: UIButton = UIButton(uri: "", text: "Reload page", color: .blue)

	static var backToVoteadmin: UIButton = UIButton(uri: "/voteadmin/", text: "⬅︎Back to overview", color: .blue)
	
	static var backToPlaza: UIButton = 	UIButton(uri: .plaza, text: "Back to plaza", color: .blue)

	static var createGroup: UIButton = UIButton(uri: .create, text: "Create group", color: .green)
	

}
