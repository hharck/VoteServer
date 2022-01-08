import VoteKit
import Vapor
import Logging

typealias JoinPhrase = String

/// Represents a collection of groups
actor GroupsManager{
	/// Groups represented by the session ID of the admin(s)
	private var groupsBySession = [SessionID: Group]()
	/// Groups represented by theit join phrase
	private var groupsByPhrase = [JoinPhrase: Group]()
	/// Groups represented by their internal id
	private var groupsByUUID = [UUID: Group]()
	/// The last time a group was accessed, used for manual garbage collection
	private var lastAccessForGroup = [UUID: Date]()
	/// JoinPhrases already reserved
	public var reservedPhrases = Set<JoinPhrase>()
	/// The hashed password for the given JoinPhrase
	public var pwdigestForJF = [JoinPhrase: String]()
	
	private let logger = Logger(label: "Groups")
}


//MARK: Store last access
extension GroupsManager{
	private func updateAccessTimeFor(_ id: UUID){
		lastAccessForGroup[id] = Date()
	}
	
	private func updateAccessTimeFor(_ group: Group){
		updateAccessTimeFor(group.id)
	}
}

//MARK: Get and create groups
extension GroupsManager{
	func groupForSession(_ session: SessionID) -> Group?{
		if let group = groupsBySession[session]{
			updateAccessTimeFor(group)
			return group
		} else {
			return nil
		}
	}
	
	func groupForGroupID(_ id: UUID) -> Group?{
		if let group = groupsByUUID[id]{
			updateAccessTimeFor(group)
			return group
		} else {
			return nil
		}
	}
	
	func groupForJoinPhrase(_ jf: JoinPhrase) -> Group?{
		if let group = groupsByPhrase[jf]{
			updateAccessTimeFor(group)
			return group
		} else {
			return nil
		}
	}
	
	func createGroup(session: SessionID, name: String, constituents: Set<Constituent>, pwdigest: String, allowsUnverified: Bool) async{
		let jf = createJoinPhrase()
		let group = Group(adminSessionID: session, name: name, constituents: constituents, joinPhrase: jf, allowsUnverifiedConstituents: allowsUnverified)
		groupsBySession[group.adminSessionID] = group
		groupsByPhrase[jf] = group
		groupsByUUID[group.id] = group
		updateAccessTimeFor(group)
		pwdigestForJF[jf] = pwdigest
		
		logger.info("Group \"\(name)\" was created, with the joinphrase \"\(jf)\"")
	}
	
	/// Attempts to login using a joinphrase and the corresponding password
	func login(request: Request, joinphrase: JoinPhrase, password: String) async -> AdminSession?{
		if let digest = pwdigestForJF[joinphrase],
		   (try? request.password.verify(password, created: digest)) == true,
		   let sessionID = groupForJoinPhrase(joinphrase)?.adminSessionID
		{
			logger.info("An admin logged in to a group with the joinphrase \"\(joinphrase)\"")
			return AdminSession(sessionID: sessionID)
		} else {
			return nil
		}
	}
}

//MARK: Support for creating joinphrases
extension GroupsManager{
	func createJoinPhrase() -> JoinPhrase{
		let phrase = joinPhraseGenerator()
		
		// If a phrase can be inserted without overwriting another element then it must be unique
		if reservedPhrases.insert(phrase).inserted {
			return phrase
		} else {
			//Otherwise we'll try again
			return createJoinPhrase()
		}
	}
}

//MARK: Convenience getters
extension GroupsManager{
	func groupAndVoterForReq(req: Request) async -> (Group, Constituent)?{
		guard
			let groupID = req.session.authenticated(GroupSession.self),
			let constID = req.session.authenticated(VoterSession.self),
			let group = self.groupForGroupID(groupID),
			let constituent = await group.constituentsSessionID[constID]
		else {return nil}
		
		return (group, constituent)
	}
}





