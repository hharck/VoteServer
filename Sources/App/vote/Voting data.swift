import Foundation
import AltVoteKit

struct VotingData: Codable{
	var userID: String
	var priorities: [Int: String]
	
	
	func asSingleVote(for vote: Vote) async throws -> SingleVote{
		let defaultUUID = "3196F9B8-935C-4018-846F-037D741C0057"
		
		//Gets the priorities in the order the user sees them
		let orderedPriorities = (1...(await vote.options.count)).compactMap{priorities[$0]}
		
		//Converts from String to UUID
		let treatedPriorities = orderedPriorities.compactMap{ value -> UUID? in
			if value == defaultUUID{
				return nil
			} else {
				return UUID(uuidString: value)
			}
		}
		
		
		
		print(treatedPriorities)
		guard treatedPriorities.nonUniques.isEmpty else {
			throw VotingDataError.allShouldBeDifferent
		}
		
		let voteOptions = await vote.options
		
		//Converts from UUID to VoteOption
		let realOptions = treatedPriorities.compactMap{prio in
			voteOptions.first{option in
				option.id == prio
			}
		}
		
		//Checks that all of the supplied priorities are used
		guard treatedPriorities.count == realOptions.count else {
			throw VotingDataError.invalidRequest
		}
		
		// Finds the identifier of the user
		let trimmedID = userID.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmedID.isEmpty else {
			throw VotingDataError.invalidUserId
		}
		
		//If the user exists, find them
		var constituent: Constituent! = await vote.eligibleVoters.first{$0.identifier == trimmedID}
				
		//If it doesn't, create one, unless disallowed by validators
		if constituent == nil{
			if !(await vote.validators.contains(where: {$0.id == VoteValidator.onlyVerifiedVotes.id})) {
				constituent = Constituent(identifier:trimmedID)
			} else {
				throw VotingDataError.invalidUserId
			}
		}
		
		//Check for preferenceForAllCandidates validator
		if await vote.validators.contains(where: {$0.id == VoteValidator.preferenceForAllCandidates.id}){
			guard Set(realOptions) == Set(await vote.options) else {
				throw VotingDataError.allShouldBeFilledIn
			}
		}
		
		return SingleVote(constituent, rankings: realOptions)
	}
}

enum VotingDataError: ErrorString{
	func errorString() -> String {
		switch self {
		case .invalidRequest:
			return "Invalid request, try reloading the page and try again"
		case .invalidUserId:
			return "Invalid user id"
		case .allShouldBeDifferent:
			return "Two or more priorities is the same"
		case .attemptedToVoteMultipleTimes:
			return "You've attempted to vote multiple times"
		case .allShouldBeFilledIn:
			return "You haven't put in a preference for all candidates"
		}
	}
	
	case invalidRequest
	case invalidUserId
	case allShouldBeDifferent
	case attemptedToVoteMultipleTimes
	case allShouldBeFilledIn
}
