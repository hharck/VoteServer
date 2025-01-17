struct GroupJoinUI: UIManager{
    internal init(title: String, joinPhrase: String = "", userID: String = "", errorString: String? = nil, showRedirectToPlaza: Bool) {
		self.title = title
		self.prefilledJoinPhrase = joinPhrase
		self.prefilledUserid = userID
		self.errorString = errorString
        
        if showRedirectToPlaza{
            self.buttons = [.backToPlaza, .createGroup, .login]
        } else {
            self.buttons = [.createGroup, .login]
        }
	}
	
    var title: String
	var prefilledJoinPhrase: String
	var prefilledUserid: String
	var errorString: String?
    var buttons: [UIButton]
	static let template: String = "joingroup"
}
