struct GroupJoinUI: UIManager{
    internal init(title: String, joinPhrase: String = "", userID: String = "", errorString: String? = nil, showRedirectToPlaza: Bool) {
		self.title = title
		self.prefilledJF = joinPhrase
		self.prefilledUserid = userID
		self.errorString = errorString
        
        if showRedirectToPlaza{
            self.buttons = [.backToPlaza, .createGroup, .login]
        } else {
            self.buttons = [.createGroup, .login]
        }
	}
	
    var version: String = App.version
    var title: String
	var prefilledJF: String
	var prefilledUserid: String
	var errorString: String?
    var buttons: [UIButton]
	static var template: String = "joingroup"
}
