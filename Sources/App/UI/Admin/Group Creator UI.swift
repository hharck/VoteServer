struct GroupCreatorUI: UIManager{
	internal init(errorString: String? = nil, _ persistentData: GroupCreatorData? = nil) {
		self.groupName = persistentData?.groupName ?? ""
		self.usernames = persistentData?.usernames.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
		self.allowsNonVerifiedUsers = persistentData?.allowsNonVerified() ?? false
		
		self.errorString = errorString
	}
	
	private var groupName: String
	private var usernames: String
	private var allowsNonVerifiedUsers: Bool
	
	var buttons: [UIButton] = [.init(uri: "/login/", text: "Go to login", color: .green)]
	
	var title: String = "Create grouped vote"
	var errorString: String? = nil
	
	static var template: String = "creategroup"
}
