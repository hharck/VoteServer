struct UIButton: Codable {
	internal init(uri: String, text: String, color: ButtonColors, lockable: Bool = false, downloadable: Bool = false) {
        assert(uri.last == "/" || uri == "", "Button URI without trailing slash")
        self.uri = uri
		self.text = text
		self.color = color
		self.lockable = lockable
		self.downloadable = downloadable
	}

	internal init(uri: RedirectionPaths, text: String, color: ButtonColors, lockable: Bool = false) {
		self.init(uri: "/" + uri.stringValue() + "/", text: text, color: color, lockable: lockable, downloadable: false)
	}

	let uri: String
	let text: String
	let color: ButtonColors
	let lockable: Bool
	let downloadable: Bool

    // Colors as defined in /Public/css/css.css
	enum ButtonColors: String, Codable {
		case blue, green, red, grey
	}

	// MARK: Default buttons
	static let reload = UIButton(uri: "", text: "Reload page", color: .blue)
	static let backToAdmin = UIButton(uri: .admin, text: "⬅︎Back to overview", color: .blue)
	static let backToPlaza = 	UIButton(uri: .plaza, text: "⬅︎Back to plaza", color: .blue)
	static let createGroup = UIButton(uri: .create, text: "Create group", color: .green)
    static let join = UIButton(uri: .join, text: "Join", color: .green)
    static let login = UIButton(uri: .login, text: "Admin login", color: .green)
}
