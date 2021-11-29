struct UIButton: Codable{
	internal init(uri: String, text: String, color: ButtonColors, lockable: Bool = false, downloadable: Bool = false) {
		self.uri = uri
		self.text = text
		self.color = color
		self.lockable = lockable
		self.downloadable = downloadable
	}
	
	internal init(uri: redirectionPaths, text: String, color: ButtonColors, lockable: Bool = false) {
		self.init(uri: "/" + uri.stringValue() + "/", text: text, color: color, lockable: lockable, downloadable: false)
	}
	
	let uri: String
	let text: String
	let color: ButtonColors
	let lockable: Bool
	let downloadable: Bool
	
	enum ButtonColors: String, Codable{
		case blue, green, red, grey
	}
	
	//MARK: Default buttons
	static var reload: UIButton = UIButton(uri: "", text: "Reload page", color: .blue)
	
	static var backToVoteadmin: UIButton = UIButton(uri: .voteadmin, text: "⬅︎Back to overview", color: .blue)
	
	static var backToPlaza: UIButton = 	UIButton(uri: .plaza, text: "Back to plaza", color: .blue)
	
	static var createGroup: UIButton = UIButton(uri: .create, text: "Create group", color: .green)
}
