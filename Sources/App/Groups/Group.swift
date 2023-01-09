import Foundation
import AltVoteKit
import VoteKit
import Logging
import WebSocketKit
import FluentKit

actor Group{
	typealias VoteID = UUID
	typealias GroupID = UUID

	internal init(_ group: DBGroup) {
		self.id = group.id!
		self.name = group.name
		self.joinPhrase = group.joinphrase
		self.logger = Logger(label: "Group \"\(name)\":\"\(joinPhrase)\"")
		self.socketController = ChatSocketController(group)
	}
	
	
	// Votes
	/// The open/closedness status of a vote
	/// Default is closed
	private var statusForVote = [VoteID: VoteStatus]()
	
    /// The different kinds of votes, stored by their id
	private var vvID = [VoteID: any DVoteProtocol]()
	
	// Cached values
	
	/// Controller for all WebSockets used by this group
	let socketController: ChatSocketController
	
	// Values from DB
	/// The ID of  the group
	let id: GroupID
	/// The name of the group as shown in the UI
	let name: String
	/// The joinPhrase used for constituents to join the group, set doing load from DB
	let joinPhrase: JoinPhrase
	
	private let logger: Logger
	
	deinit{
		Task{
			await socketController.kickAll()
		}
	}

}

//MARK: Get constituents and their status
//extension Group{
//	
//    //Retrieves verified constituents by their identifier
//	func verifiedConstituent(for identifier: ConstituentIdentifier) -> Constituent?{
//		verifiedConstituents.first(where: {$0.identifier == identifier})
//	}
//    //Retrieves unverified constituents by their identifier
//	func unverifiedConstituent(for identifier: ConstituentIdentifier) -> Constituent?{
//		unverifiedConstituents.first(where: {$0.identifier == identifier})
//	}
//	
//    //Retrieves constituents by their identifier, not regarding whether they're verified
//	func constituent(for identifier: ConstituentIdentifier) -> Constituent?{
//		if let v = verifiedConstituent(for: identifier){
//			return v
//		} else {
//			return unverifiedConstituent(for: identifier)
//		}
//	}
//	
//	// Returns a set of all constituents who has ever been in this group
//	func allPossibleConstituents() -> Set<Constituent>{
//		verifiedConstituents
//			.union(unverifiedConstituents)
//		//Converts the previously joined into "real" constituents
//            .union(previouslyJoinedUnverifiedConstituents.map(Constituent.init))
//	}
//	
//	func constituentIsVerified(_ const: Constituent) -> Bool{
//		verifiedConstituents.contains(const)
//	}
//	
//	func constituentHasJoined(_ identifier: ConstituentIdentifier) -> Bool{
//		joinedConstituentsByID.values.contains(where: {$0.identifier == identifier})
//	}
//}

//MARK: Reset/disallow constituents
extension Group{
	
	func resetConstituent(_ constituent: Constituent, userid: UUID, isVerified: Bool) async{
		// Removes unverified from all votes
		if !isVerified{
			for v in vvID.values {
				await v.removeConstituent(constituent)
			}
		}

		await self.socketController.close(userid: userid)
		
		logger.info("Constituent \"\(constituent.identifier)\" was reset")
	}
	
    /// Changes whether unverified constituents are allowed in this group.
    ///  Handles rule changes and removes unverified constituents from all votes they haven't cast a vote in
    /// - Parameter state: if false every constituent that isn't on the verified list will be removed else allowsUnverifiedConstituents will be set to true
	func setRemoveUnverifiedConstituents(_ unverifiedConstituents: Set<Constituent>) async{
		// Kicks all unverified constituents from their WebSocket
		await self.socketController.kickAll(only: .unverified)
		
		//Removes all unverified constituents who hasn't cast a vote
		for v in vvID.values{
			await v.removeUnverifiedConstituents(unverifiedConstituents)
		}
	}
}

extension VoteProtocol {
	func removeUnverifiedConstituents(_ unverifiedConstituents: Set<Constituent>) async {
		self.constituents = constituents
		// Removes all unverified
			 .subtracting(unverifiedConstituents)
		// Adds everyone who has already voted, including unverified
			 .union(votes.map(\.constituent))
	}
}

////MARK: Join
//extension Group{
//    
//    /// Adds a constituent to the group
//    /// - Parameters:
//    ///   - const: The constituent to add
//    ///   - sessionId: The session from which a client signed in
//    /// - Returns: True if the constituent could be added
//	func joinConstituent(_ const: Constituent, for sessionId: SessionID) async -> Bool {
//		guard joinedConstituentsByID[const.identifier] == nil else {
//			return false
//		}
//		
//		if !verifiedConstituents.contains(const){
//			if unverifiedConstituents.contains(const){
//				assertionFailure()
//				logger.warning("\"\(const.getNameOrId())\" is stored in unverifiedConstituents eventhough it's not joined")
//                return false
//			}
//			
//            guard settings.allowsUnverifiedConstituents else {
//				assertionFailure("joinConstituent was called with an unverified constituent")
//				logger.warning("joinConstituent was called with an unverified constituent")
//				return false
//			}
//			
//			unverifiedConstituents.insert(const)
//			previouslyJoinedUnverifiedConstituents.remove(const.identifier)
//			
//			
//			for v in AltVotesByID.values{
//				await v.addConstituents(const)
//			}
//			for v in YNVotesByID.values{
//				await v.addConstituents(const)
//			}
//			for v in SimMajVotesByID.values{
//				await v.addConstituents(const)
//			}
//			
//		}
//		defer{
//			logger.info("Constituent \(const.identifier) joined the group")
//		}
//		
//		constituentsSessionID[sessionId] = const
//		
//		joinedConstituentsByID[const.identifier] = const
//		return true
//	}
//	
//}

//MARK: Handle votes (elections)
extension Group {
    /// Finds a vote by its id
    func voteForID(_ id: VoteID) -> (any DVoteProtocol)?{
		guard let vote = vvID[id] else { return nil }
		return vote
    }
	
    /// Finds a vote by a string representation of its id
    func voteForID(_ id: String) -> (any DVoteProtocol)?{
        guard let voteID = VoteID(id) else {
            return nil
        }
        return voteForID(voteID)
    }
    
    
	/// Returns three arrays, all containing all instances for each kind of vote
	func allVotes() -> [any DVoteProtocol] {
		return Array(vvID.values)
	}

    /// Gets the status for the id of a vote
    func statusFor(_ id: VoteID) async -> VoteStatus?{
        return statusForVote[id]
    }
    
	/// Gets the status of a vote
	func statusFor(_ vote: any DVoteProtocol) async -> VoteStatus?{
        statusForVote[await vote.id]
	}

	func setStatusFor(_ vote: any DVoteProtocol, to value: VoteStatus) async{
        await setStatusFor(await vote.id, to: value)
	}
    func setStatusFor(_ vote: VoteID, to value: VoteStatus) async{
		let oldValue = statusForVote[vote]
		statusForVote[vote] = value
		
		// If changed to open, ask clients to reload
		if oldValue == .closed && value == .open{
			await socketController.sendToAll(msg: .requestReload, async: true, includeAdmin: false)
		}
    }
	
	/// Adds new votes to the group
	func addVoteToGroup(vote: any DVoteProtocol) async{
		let voteID = await vote.id
		vvID[voteID] = vote
		statusForVote[voteID] = .closed
        let vName = await vote.name
		logger.info("Vote named \"\(vName)\" was added to the group")
	}
    
    /// Removes a vote (election) from this Group
    func removeVoteFromGroup(vote: any DVoteProtocol) async {
        let id = await vote.id

        self.statusForVote[id] = nil
		vvID[id] = nil
    }
	
    /// Removes a vote by the constituent in the group given in the URL; if the user has been kicked out, it will be removed from the vote's list of verified constituents
    func singleVoteReset(vote: any DVoteProtocol, linker: GroupConstLinker) async{
		let constituentID = linker.constituent.username
		await vote.resetVoteForUser(constituentID)
        
        // If the user is no longer in the group, it'll be removed from the constituents list in the vote
        if linker.isBanned{
            let newConstitutents = await vote.constituents.filter{ const in
                const.identifier != constituentID
            }
            await vote.setConstituents(newConstitutents)
        }
    }
}

enum VoteStatus: String, Codable{
	case open = "open"
	case closed = "close"
}
