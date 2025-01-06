struct AdminChatPage: UIManager{
    var version: String = App.version
	var title: String = "Chats"
	var errorString: String? = nil
	static let template: String = "adminchatpage"
	
	var buttons: [UIButton] = [.backToAdmin,]
}
