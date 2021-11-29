import Foundation
import AltVoteKit
import Logging

actor Group{
	typealias VoteID = UUID
	
	internal init(adminSessionID: SessionID, name: String, constituents: Set<Constituent>, joinPhrase: JoinPhrase, allowsUnVerifiedVoters: Bool) {
		self.adminSessionID = adminSessionID
		self.name = name
		self.verifiedConstituents = constituents
		self.joinPhrase = joinPhrase
		self.allowsUnVerifiedVoters = allowsUnVerifiedVoters
		
		self.logger = Logger(label: "Group \"\(name)\":\"\(joinPhrase)\"")
	}
	
	/// The name of the group as shown in the UI
	let name: String
	/// The joinPhrase used for constituents to join  the group
	let joinPhrase: JoinPhrase
	/// The ID of  the group
	let id: UUID = UUID()
	
	/// Admin session ID
	let adminSessionID: SessionID
	/// The open/closedness status of a vote
	private var statusForVote = [VoteID: VoteStatus]()
	private var votesByID = [VoteID: AltVote]()
	
	private(set) var verifiedConstituents: Set<Constituent>
	private(set) var unVerifiedConstituents: Set<Constituent> = []
	
	var allowsUnVerifiedVoters: Bool
	
	var joinedConstituentsByID = [ConstituentID: Constituent]()
	
	/// A dictionary of unverified constituents who has been removed one way or another
	var previouslyJoinedUnverifiedConstituents = Set<ConstituentID>()
	
	var constituentsSessionID: [UUID: Constituent] = [:]
	
	private let logger: Logger
}


//MARK: Get constituents and their status
extension Group{
	
	func verifiedConstituent(for identifier: ConstituentID) -> Constituent?{
		verifiedConstituents.first(where: {$0.identifier == identifier})
	}
	
	func unVerifiedConstituent(for identifier: ConstituentID) -> Constituent?{
		unVerifiedConstituents.first(where: {$0.identifier == identifier})
	}
	
	func constituent(for identifier: ConstituentID) -> Constituent?{
		if let v = verifiedConstituent(for: identifier){
			return v
		} else {
			return unVerifiedConstituent(for: identifier)
		}
	}
	
	
	func constituentIsVerified(_ const: Constituent) -> Bool{
		verifiedConstituents.contains(const)
	}
	
	
	func constituentHasJoined(_ identifier: ConstituentID) -> Bool{
		joinedConstituentsByID.values.contains(where: {$0.identifier == identifier})
	}
}

//MARK: Reset/disallow constituents
extension Group{
	func resetConstituent(_ constituent: Constituent) async{
		if unVerifiedConstituents.contains(constituent){
			self.unVerifiedConstituents.remove(constituent)
			self.previouslyJoinedUnverifiedConstituents.insert(constituent.identifier)
			
			for i in self.votesByID.values{
				// If the constituent hasn't cast a vote it will be removed from the list of eligible voters in a vote
				if !(await i.votes.map(\.constituent.identifier).contains(constituent.identifier)){
					//FIXME: Compiler workaround for "await i.constituents.remove(constituent)"
					await i.constituents = await i.constituents.filter{ const in
						const != constituent
					}
				}
			}
		}
		
		self.joinedConstituentsByID[constituent.identifier] = nil
		
		// Removes all sessionIDs referencing the one being deleted
		constituentsSessionID = constituentsSessionID.filter{ ID, const in
			return constituent.identifier != const.identifier
		}
		
		logger.info("Constituent \"\(constituent.identifier)\" was reset")
	}
	
	/// - Parameter state: if false every constituent that isn't on the verified list will be removed else allowsUnVerifiedVoters will be set to true
	func setAllowsUnVerifiedVoters(_ state: Bool) async{
		guard state != self.allowsUnVerifiedVoters else {return}
		if !state{
			/// Adds all unverified constituens to previouslyJoinedUnverifiedConstituents
			previouslyJoinedUnverifiedConstituents.formUnion(unVerifiedConstituents.map(\.identifier))
			
			//Removes all unverified constituents who hasn't cast a vote
			for vote in allVotes() {
				await vote
					.setConstituents(vote.constituents
									 // Removes all unverified
										.subtracting(unVerifiedConstituents)
									 // Adds everyone who has already voted, including unverified
										.union(vote.votes.map(\.constituent)))
			}
			
			// Removes all sessionIDs referencing the one being deleted
			let unverifiedIdentifiers = unVerifiedConstituents.map(\.identifier)
			constituentsSessionID = constituentsSessionID.filter{ _, const in
				return unverifiedIdentifiers.contains(const.identifier)
			}
			
			unVerifiedConstituents = []
			joinedConstituentsByID = joinedConstituentsByID.filter{(_, value) in
				verifiedConstituents.contains(value)
			}
		}
		self.allowsUnVerifiedVoters = state
		
		logger.info("Access for unverified was set to: \(state)")
	}
}

//MARK: Join
extension Group{
	func joinConstituent(_ const: Constituent, for sessionId: SessionID) async -> Bool {
		guard joinedConstituentsByID[const.identifier] == nil else {
			return false
		}
		
		if !verifiedConstituents.contains(const){
			assert(!unVerifiedConstituents.contains(const))
			
			guard allowsUnVerifiedVoters else {
				assertionFailure("joinConstituent was called with an unverified constituent")
				return false
			}
			
			unVerifiedConstituents.insert(const)
			previouslyJoinedUnverifiedConstituents.remove(const.identifier)
			
			for vote in votesByID.values{
				await vote.addConstituents(const)
			}
		}
		defer{
			logger.info("Constituent \(const.identifier) joined the group")
		}
		
		constituentsSessionID[sessionId] = const
		
		joinedConstituentsByID[const.identifier] = const
		return true
	}
	
}

//MARK: Handle votes (elections)
extension Group {
	func voteForID(_ id: String) async -> AltVote?{
		if let voteID = VoteID(id){
			return votesByID[voteID]
		} else {
			return nil
		}
	}
	
	func voteForID(_ id: VoteID) -> AltVote?{
		votesByID[id]
	}
	
	func allVotes() -> [AltVote]{
		Array(self.votesByID.values)
	}
	/// Get the status of a vote
	func statusFor(_ vote: AltVote) async -> VoteStatus?{
		statusForVote[await vote.id]
	}
	
	func setStatusFor(_ vote: AltVote, to value: VoteStatus) async{
		statusForVote[await vote.id] = value
		
		logger.info("\"\(Task{await vote.name})\" was set to \"\(value)\"")
	}
	
	/// Adds new votes to the group
	func addVoteToGroup(vote: AltVote) async{
		let voteID = await vote.id
		votesByID[voteID] = vote
		statusForVote[voteID] = .closed
		
		logger.info("Vote named \"\(Task{await vote.name})\" was added to the group")
	}
	
	/// The session used for "proving" membership of a group
	var groupSession: GroupSession{
		return .init(sessionID: self.id)
	}
}


enum VoteStatus: String, Codable{
	case open
	case closed
}
