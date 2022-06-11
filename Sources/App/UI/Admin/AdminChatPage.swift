struct AdminChatPage: UIManager{
	var title: String = "Chats"
	var errorString: String? = nil
	var generalInformation: HeaderInformation! = nil
	static var template: String = "adminchatpage"
	
	var buttons: [UIButton] = []
}
