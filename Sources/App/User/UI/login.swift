struct LoginUI: UIManager{
    internal init(prefilledUN: String? = nil, errorString: String? = nil) {
		self.errorString = errorString
		self.prefilledUN = prefilledUN
	}
	
    var buttons: [UIButton] = []
	
	var title: String = "Login"
	
	var errorString: String? = nil
	var generalInformation: HeaderInformation! = nil
	
	var prefilledUN: String?
	
	static var template: String = "login"
	
}
