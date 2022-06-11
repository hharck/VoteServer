import Foundation

struct UIButton: Codable{
	internal init(uri: String, text: String, color: ButtonColors, lockable: Bool = false, inGroup: Bool = false, downloadable: Bool = false) {
        assert(uri.last == "/" || uri == "", "Button URI without trailing slash")
        self.uri = uri
		self.text = text
		self.color = color
		self.lockable = lockable
		self.downloadable = downloadable
		self.inGroup = inGroup
	}
	
	internal init(uri: RedirectionPaths, text: String, color: ButtonColors, lockable: Bool = false) {
		self.init(uri: "/" + uri.stringValue() + "/", text: text, color: color, lockable: lockable, inGroup: false, downloadable: false)
	}
	
	internal init(uri: GroupSpecificPaths, text: String, color: ButtonColors, lockable: Bool = false) {
		self.init(uri: "/" + uri.stringValue() + "/", text: text, color: color, lockable: lockable, inGroup: true, downloadable: false)
	}
	
	
	let uri: String
	let text: String
	let color: ButtonColors
	let lockable: Bool
	let downloadable: Bool
	let inGroup: Bool
	
    /// Colors as defined in `/Public/css/css.css`
	enum ButtonColors: String, Codable{
		case blue, green, red, grey
	}
	
	//MARK: Default buttons
	static var reload: UIButton = UIButton(uri: "", text: "Reload page", color: .blue)
    static var join: UIButton = UIButton(uri: .join, text: "Join", color: .green)
	static var signup: UIButton = UIButton(uri: .signup, text: "Sign up", color: .green)
    static var login: UIButton = UIButton(uri: .login, text: "Admin login", color: .green)
	
	struct GroupOnly{
		static var backToPlaza: UIButton =	UIButton(uri: .plaza, text: "⬅︎Back to plaza", color: .blue)
		
		/// Prevent calls to init
		private init(){}
	}
}
/*
 //	static func backToAdmin(_ groupID: UUID) -> UIButton{
 //		UIButton(uri: .admin(group: groupID.uuidString), text: "⬅︎Back to overview", color: .blue)
 //	}
 //	static func backToPlaza(_ groupID: UUID) -> UIButton{
 //		UIButton(uri: .plaza(group: groupID.uuidString), text: "⬅︎Back to plaza", color: .blue)
 //	}
 */
