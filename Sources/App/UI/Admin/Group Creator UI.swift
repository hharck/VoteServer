struct GroupCreatorUI: UIManager{
    var version: String = App.version
    var title: String = "Create grouped vote"
	var errorString: String? = nil
	
	var buttons: [UIButton] = [.join, .login]
	
	static let template: String = "creategroup"
	
	private var groupName: String?
	private var allowsUnverifiedConstituents: Bool
    private var generatePasswords: Bool
	
	internal init(errorString: String? = nil, _ persistentData: GroupCreatorData? = nil) {
		self.groupName = persistentData?.groupName
		self.allowsUnverifiedConstituents = persistentData?.allowsUnverified ?? Config.defaultValueForUnverifiedConstituents
        self.generatePasswords = persistentData?.requiresPasswordGeneration ?? false
		self.errorString = errorString
	}
}
import Vapor
extension GroupCreatorUI{
	//Convenience init allowing a direct call from routes
	init(req: Request){
		self.init(errorString: nil, nil)
	}
}
