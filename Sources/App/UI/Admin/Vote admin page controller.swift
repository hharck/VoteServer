import VoteKit
import FluentKit
/// A page showing the validators, options and constituents in a vote
struct VoteAdminUIController: UITableManager{
	let title: String
	var errorString: String? = nil
	var generalInformation: HeaderInformation! = nil

	var tableHeaders = ["", "User id", "Name", "Has voted", "Verified", ""]
	let rows: [ConstituentAndStatus]
	
	var buttons: [UIButton] = [.reload]

    /// The name of the vote
	private var voteName: String
    
	/// Show the "Get results" button
	private let showGetResults: Bool

	/// Show the  "Close vote" button or the "Open vote" and "Delete vote" buttons
	private let isOpen: Bool
	
	/// Number of votes cast
	private let voteCount: Int
	/// The number of voters who is verified and/or has joined the group 
	private let constituentsCount: Int
	
	/// The options available for the vote
	private let options: [String]
	
	/// Special settings added to the vote
	private let settings: [String]
	
	/// The id for the vote being presented
	private let voteID: String
	
	static var template: String = "voteadmin"
    
	init<V: DVoteProtocol>(vote: V, group: DBGroup, status: VoteStatus, db: Database) async throws {
		self.voteCount = await vote.votes.count
		self.constituentsCount = await vote.constituents.count
		
		// Sets the page title to the name of the vote, and conditionally adds " (closed)"
		self.title = await vote.name + (status == .open ? "" : " (closed)")
		self.voteName = await vote.name
		self.showGetResults = voteCount >= 2 && status == .closed
		self.isOpen = status == .open
		
		self.voteID = await vote.id.uuidString
		self.settings = await vote.particularValidators.map(\.name) + vote.genericValidators.map(\.name)
		self.options = await vote.options.map(\.name)
		
		var tempRows = [ConstituentIdentifier: ConstituentAndStatus]()
		
		let votes = await vote.votes
		
		let verified = try await group
			.$constituents
			.query(on: db)
			.filter(\.$isBanned == false)
			.filter(\.$isVerified == true)
			.join(parent: \.$constituent)
			.all()
			.map{try $0.joined(DBUser.self)}
		let unverified = try await group
			.$constituents
			.query(on: db)
			.filter(\.$isBanned == false)
			.filter(\.$isVerified == false)
			.join(parent: \.$constituent)
			.all()
			.map{try $0.joined(DBUser.self)}
		
		let defaultImageURL = getDefaultGravatar(size: 30)
		//NB: Three seperate loops gives a worst case complexity of O(k + ln(k)*m+ln(k+m)*n), instead of nested loops which has a worst case scenario of O(k*(m*ln(k)+n*ln(k+m))
		votes.forEach { vote in
			tempRows[vote.constituent.identifier] = ConstituentAndStatus(identifier: vote.constituent.identifier, name: vote.constituent.name, hasVoted: true, isVerified: false, imageURL: defaultImageURL)
		}
		
		//TODO: Simplify
		for const in verified{
			let imageURL = getGravatarURLForUser(const, size: 30)
			if tempRows[const.username] != nil {
				tempRows[const.username]!.isVerified = true
				tempRows[const.username]!.imageURL = imageURL
			} else {
				tempRows[const.username] = ConstituentAndStatus(identifier: const.username, name: const.name, hasVoted: false, isVerified: true, imageURL: imageURL)
			}
		}
		
		for const in unverified {
			if tempRows[const.username] == nil {
				tempRows[const.username] = ConstituentAndStatus(identifier: const.username, name: const.name, hasVoted: false, isVerified: false)
			}
		}
		
		self.rows = tempRows.map(\.value).sorted{ lhs, rhs in
			return lhs.constIdentifier < rhs.constIdentifier
		}
	}
	
	struct ConstituentAndStatus: Codable{
		internal init(identifier: String, name: String?, hasVoted: Bool, isVerified: Bool, imageURL: String? = nil) {
			self.constName = name ?? identifier
			self.constIdentifier = identifier
			self.constB64ID = identifier.asURLSafeBase64()
			
			self.hasVoted = hasVoted
			self.isVerified = isVerified
			self.imageURL = imageURL
		}
		
		var constName: String
		var constIdentifier: String
		var constB64ID: String?
		var hasVoted: Bool
		var isVerified: Bool
		var imageURL: String?
	}
}

