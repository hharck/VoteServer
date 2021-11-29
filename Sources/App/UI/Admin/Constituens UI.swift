import AltVoteKit
struct ConstituentsListUI: UITableManager{
	var title: String = "Constituents"
	var errorString: String? = nil
	
	var buttons: [UIButton] = [.backToVoteadmin, .reload]
	
	var tableHeaders = ["User id", "Name", "Is verified", ""]
	var rows: [ConstituentData] = []

	var allowsNonVerified: Bool
	
	static var template: String = "constituents list"
	
	init(group: Group) async{
		let verified = await group.verifiedConstituents
		let unVerified = await group.unVerifiedConstituents
		
		self.allowsNonVerified = await group.allowsUnVerifiedVoters
		
		assert(verified.isDisjoint(with: unVerified))
		
		for const in verified{
			rows.append(await ConstituentData(constituent: const, group: group, isVerified: true))
			
		}
		
		for const in unVerified {
			rows.append(await ConstituentData(constituent: const, group: group, isVerified: false))
		}
		
		rows.sort{$0.userID < $1.userID}
	}
	
	struct ConstituentData: Codable{
		internal init(constituent: Constituent, group: Group, isVerified: Bool) async{
			self.userID = constituent.identifier
			self.name = constituent.name ?? ""
			
			self.isVerified = isVerified
			self.hasJoined = await group.constituentHasJoined(constituent.identifier)
		}
		
		var userID: String
		var name: String
		var isVerified: Bool
		var hasJoined: Bool
	}
}


