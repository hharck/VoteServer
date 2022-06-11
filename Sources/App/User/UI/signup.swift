struct SignupUI: UIManager{
	internal init(prefilledName: String? = nil, prefilledUN: String? = nil, prefilledEmail: String? = nil, errorString: String? = nil) {
		self.errorString = errorString
		self.prefilledUN = prefilledUN
		self.prefilledEmail = prefilledEmail
		self.prefilledName = prefilledName
	}
	
	var buttons: [UIButton] = []
	
	var title: String = "Signup"
	
	var errorString: String? = nil
	var generalInformation: HeaderInformation! = nil
	
	var prefilledName: String?
	
	var prefilledUN: String?
	
	var prefilledEmail: String?
	
	static var template: String = "signup"
	
}
