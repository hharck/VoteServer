struct AdminChatPage: UIManager{
	var title: String = "Chats"
	var errorString: String? = nil
	static let template: String = "adminchatpage"
	
	var buttons: [UIButton] = [.backToAdmin,]
}
