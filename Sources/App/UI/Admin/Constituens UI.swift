import VoteKit
struct ConstituentsListUI: UITableManager{
	var title: String = "Constituents"
	var errorString: String? = nil
	
	var buttons: [UIButton] = [.backToVoteadmin,
							   .reload,
							   .init(uri: "/voteadmin/constituents/downloadcsv/", text: "Download constituents as CSV", color: .blue, downloadable: true)
	]
	
	var tableHeaders = ["User id", "Name", "Is verified", ""]
	var rows: [ConstituentData] = []

	var allowsUnverified: Bool
	
	static var template: String = "constituents list"
	
	init(group: Group) async{
		let verified = await group.verifiedConstituents
		let unverified = await group.unverifiedConstituents
		
        self.allowsUnverified = await group.settings.allowsUnverifiedConstituents
		
		assert(verified.isDisjoint(with: unverified))
		
		for const in verified{
			rows.append(await ConstituentData(constituent: const, group: group, isVerified: true))
			
		}
		
		for const in unverified {
			rows.append(await ConstituentData(constituent: const, group: group, isVerified: false))
		}
		
		rows.sort{$0.userID < $1.userID}
	}
	
	struct ConstituentData: Codable{
		internal init(constituent: Constituent, group: Group, isVerified: Bool) async{
			self.userID = constituent.identifier
			self.name = constituent.name ?? ""
            self.userID64 = constituent.identifier.asURLSafeB64() ?? ""
			self.isVerified = isVerified
			self.hasJoined = await group.constituentHasJoined(constituent.identifier)
		}
		
		var userID: String
        var userID64: String
		var name: String
		var isVerified: Bool
		var hasJoined: Bool
	}
}
