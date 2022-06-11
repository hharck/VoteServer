import Vapor
struct GroupCreatorUI: UIManager{
	var title: String = "Create grouped vote"
	var errorString: String? = nil
	var generalInformation: HeaderInformation! = nil
	
	var buttons: [UIButton] = []
	
	static var template: String = "creategroup"
	
	private var groupName: String?
	private var allowsUnverifiedConstituents: Bool
	
	internal init(errorString: String? = nil, _ persistentData: GroupCreatorData? = nil/*, allUsersWOAdmin: [(name: String, id: UUID, tag: String)]*/) {
		self.allowsUnverifiedConstituents = persistentData?.allowsUnverified() ?? Config.defaultValueForUnverifiedConstituents
		
		self.errorString = errorString
		self.groupName = try? persistentData?.getGroupName()
	}
	
	struct UsernameAndSelection: Codable{
		let username: String
		let id: UUID
		let tag: String
		let isSelected: Bool
		
		init(_ username: String, _ id: UUID, _ tag: String, _ isSelected: Bool){
			self.username = username
			self.id = id
			self.tag = tag
			self.isSelected = isSelected
		}
	}
}

extension GroupCreatorUI{
	//Convenience init allowing a direct call from routes
	init(req: Request) throws{
		let user = try req.auth.require(DBUser.self)
		guard user.mayCreateAGroup() else {
			throw Abort(.unauthorized)
		}
		self.init()
	}
}
