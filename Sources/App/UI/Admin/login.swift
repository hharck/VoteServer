struct LoginUI: UIManager{
    internal init(prefilledJoinPhrase: String? = nil, errorString: String? = nil, showRedirectToPlaza: Bool) {
		self.errorString = errorString
		self.prefilledJoinPhrase = prefilledJoinPhrase
        
        if showRedirectToPlaza{
            self.buttons = [.backToPlaza, .join, .createGroup]
        } else {
            self.buttons = [ .join, .createGroup]
        }
	}
    
    var buttons: [UIButton]
	
	var title: String = "Login"
	
	var errorString: String?
	
	var prefilledJoinPhrase: String?
	
	static let template: String = "login"
	
}
