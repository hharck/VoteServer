struct LoginUI: UIManager{
    internal init(prefilledJF: String = "", errorString: String? = nil, showRedirectToPlaza: Bool) {
		self.errorString = errorString
		self.prefilledJF = prefilledJF
        
        if showRedirectToPlaza{
            self.buttons = [.backToPlaza, .createGroup, .join]
        } else {
            self.buttons = [.createGroup, .join]
        }
	}
	
    var buttons: [UIButton]
	
	var title: String = "Login"
	
	var errorString: String?
	
	var prefilledJF: String = ""
	
	static var template: String = "login"
	
}
