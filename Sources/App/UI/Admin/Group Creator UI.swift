struct GroupCreatorUI: UIManager{
	internal init(errorString: String? = nil, _ persistentData: GroupCreatorData? = nil) {
		self.groupName = persistentData?.groupName ?? ""
		self.usernames = persistentData?.usernames.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
		self.allowsUnverifiedConstituents = persistentData?.allowsUnverified() ?? false
		
		self.errorString = errorString
	}
	
	private var groupName: String
	private var usernames: String
	private var allowsUnverifiedConstituents: Bool
	
    var buttons: [UIButton] = [.join, .login]
	
	var title: String = "Create grouped vote"
	var errorString: String? = nil
	
	static var template: String = "creategroup"
}
