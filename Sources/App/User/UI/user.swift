struct UserUI: UITableManager{
	internal init(name: String, username: String, email: String, linkers: [GroupConstLinker]) {
		self.name = name
		self.username = username
		self.email = email
		

		self.buttons = []
		
		
		self.rows = linkers.map(GroupInformation.init)
	}
	
	var buttons: [UIButton]
	
	var title: String = "User"
	
	var errorString: String? = nil
	var generalInformation: HeaderInformation! = nil
	
	var rows: [GroupInformation]
	var tableHeaders: [String] = ["Name", "Your tag", "Admin", "Verified", "Has accepted"]
	var hideIfEmpty = true
	
	
	var name: String
	var username: String
	var email: String
	
	static var template: String = "user/user"
	
	struct GroupInformation: Codable{
		let name: String
		let groupID: String
		let tag: String?
		let isAdmin: Bool
		let isVerified: Bool
		let isCurrentlyIn: Bool
		
		init(_ linker: GroupConstLinker){
			let group = try! linker.joined(DBGroup.self)
			self.name = group.name
			self.groupID = group.id!.uuidString
			self.tag = linker.tag
			self.isAdmin = linker.isAdmin
			self.isVerified = linker.isVerified
			self.isCurrentlyIn = linker.isCurrentlyIn
		}
	}
}
