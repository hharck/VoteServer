struct GroupJoinUI: UIManager{
	internal init(title: String, joinPhrase: String = "", userID: String = "", errorString: String? = nil) {
		self.title = title
		self.prefilledJF = joinPhrase
		self.prefilledUserid = userID
		self.errorString = errorString
	}
	
	var title: String
	var prefilledJF: String
	var prefilledUserid: String
	var errorString: String?
    var buttons: [UIButton] = [.createGroup]
	static var template: String = "joingroup"
}
