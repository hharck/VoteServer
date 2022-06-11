import VoteKit
struct ConstituentsListUI: UITableManager{
	var title: String = "Constituents"
	var errorString: String? = nil
	var generalInformation: HeaderInformation! = nil
	var hideIfEmpty: Bool = true
	
	var buttons: [UIButton]
	
	var tableHeaders: [String]
	var rows: [ConstituentData] = []

	var allowsUnverified: Bool
	
	static var template: String = "constituents list"
	
	var showsTags: Bool
	var tagStats: [String]? = nil
	
	init(settings: GroupSettings, constituents: [GroupConstLinker], invites: [GroupInvite]) async throws{
		self.allowsUnverified = settings.allowsUnverifiedConstituents
		self.showsTags = settings.showTags
		
		if self.showsTags {
			self.tableHeaders = ["","User id", "Name", "Tag", "Is verified", ""]
			
			let const = invites.map { user in
				(tag: user.tag, isIn: false, isVerified: true)
			}
			+
			constituents.filter(\.isBanned).map{ user in
				(tag: user.tag, isIn: user.isCurrentlyIn, isVerified: user.isVerified)
			}
			
			self.tagStats = generateStats(constituents: const)
			
		} else {
			self.tableHeaders = ["","User id", "Name", "Is verified", ""]
		}
		
		for const in constituents {
			let imageURL = getGravatarURLForUser(try const.joined(DBUser.self), size: 30)
			rows.append(await ConstituentData(user: const, isVerified: const.isVerified, imageURL: imageURL))
		}
		
		for const in invites {
			let imageURL = getGravatarURLForInvite(try const.joined(InvitedUser.self), size: 30)
			rows.append(await ConstituentData(user: const, imageURL: imageURL))
		}
		
		rows.sort{$0.userID < $1.userID}
		
		
		buttons = [ .reload,
					.init(uri: "downloadcsv/", text: "Download constituents as CSV", color: .blue, inGroup: false, downloadable: true)
 ]
	}
	
	struct ConstituentData: Codable{
		internal init(user: GroupConstLinker, isVerified: Bool, imageURL: String?) async{
			let constituent = try! user.joined(DBUser.self)
			self.userID = constituent.username
			self.name = constituent.name
			self.userID64 = constituent.username.asURLSafeBase64()
			self.isVerified = isVerified
			self.hasJoined = user.isCurrentlyIn
			self.tag = user.tag
			self.hasAccepted = user.isCurrentlyIn
			self.imageURL = imageURL
		}
		
		internal init(user: GroupInvite, imageURL: String?) async{
			self.userID = "Not accepted:"
			self.name = try? user.joined(InvitedUser.self).email
			self.userID64 = nil
			self.isVerified = true
			self.hasJoined = false
			self.hasAccepted = false
			self.tag = user.tag
			self.imageURL = imageURL
		}
		
		let tag: String?
		let userID: String
        let userID64: String?
		let name: String?
		let isVerified: Bool
		let hasJoined: Bool
		let hasAccepted: Bool
		let imageURL: String?
	}
}


/// Calculates statistics for all tags
fileprivate func generateStats(constituents: [(tag: String?, isIn: Bool, isVerified: Bool)]) -> [String]{
	func genStat(tag: String?) {
		let tag = tag ?? "--No tag"
		let list = constituents.filter{$0.tag == tag}
		
		let num = list.filter(\.isIn).count
		let numTot = list.count
		
		genStatWithValues(tag: tag, num: num, numTot: numTot)
	}
	
	func genStatWithValues(tag: String, num: Int, numTot: Int){
		let pct = Double(num)/Double(numTot) * 100.0
		let pctStr = String(format:"%.2f", pct)
		let str = "\(tag): \(num)/\(numTot), \(pctStr)%"
		tagStats.append(str)
	}
	
	var tagStats = [String]()
	
	// Gen stats for all normal tags
	Set(constituents.map(\.tag)).forEach(genStat)
	
	// Gen stats for all implied tags
	
	genStatWithValues(tag: "--Total", num: constituents.filter(\.isIn).count, numTot: constituents.count)
	
	let allVerified = constituents.filter(\.isVerified)
	genStatWithValues(tag: "--Verified", num: allVerified.filter(\.isIn).count, numTot: allVerified.count)
	
	let allUnverified = constituents.filter{!$0.isVerified}
	if !allUnverified.isEmpty {
		genStatWithValues(tag: "--Unverified", num: allUnverified.filter(\.isIn).count, numTot: allUnverified.count)
	}
	
	return tagStats.sorted { str1, str2 in
		if str1.hasPrefix("--"){
			return str2.hasPrefix("--") && str1 < str2
		} else {
			return str2.hasPrefix("--") || str1 < str2
		}
	}
}

