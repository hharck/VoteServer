struct AdminChatPage: UIManager{
    var version: String = App.version
	var title: String = "Chats"
	var errorString: String? = nil
	static var template: String = "adminchatpage"
	
	var buttons: [UIButton] = [.backToAdmin,]
}
