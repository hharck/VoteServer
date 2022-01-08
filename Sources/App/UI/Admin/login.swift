struct LoginUI: UIManager{
	internal init(prefilledJF: String = "", errorString: String? = nil) {
		self.errorString = errorString
		self.prefilledJF = prefilledJF
	}
	
    var buttons: [UIButton] = [.createGroup, .join]
	
	var title: String = "Login"
	
	var errorString: String?
	
	var prefilledJF: String = ""
	
	static var template: String = "login"
	
}
