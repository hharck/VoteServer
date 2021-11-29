import Foundation
import AltVoteKit

struct AltVotingData: Codable{
	var priorities: [Int: String]?
	var blank: Bool?
	
	/// Gets the priorities in the order the user sees them
	func orderForOptions(_ options: [VoteOption], addDefault: Bool) -> [String]{
		let priorities = blank == true ? [:] : priorities ?? [:]
		
		if addDefault{
			return (1...(options.count)).map{priorities[$0] ?? "default"}
		} else {
			return (1...(options.count)).compactMap{priorities[$0]}
		}
			
	}
	
	func asSingleVote(for vote: AltVote, constituent: Constituent) async throws -> SingleVote{
		
		let defaultValue = "default"
		
		//Gets the priorities in the order the user sees them
		let orderedPriorities = orderForOptions(await vote.options, addDefault: false)
		
		//Converts from String to UUID
		let treatedPriorities = orderedPriorities.compactMap{ value -> UUID? in
			if value == defaultValue{
				return nil
			} else {
				return UUID(uuidString: value)
			}
		}
		
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
		
		
		//Check for violations of the NoBlanks validator
		let noBlankId = VoteValidator.noBlankVotes.id
		let noBlanks = await vote.validators.contains(where: {$0.id == noBlankId})
		if realOptions.isEmpty && noBlanks{
			throw VotingDataError.blankVotesNotAllowed
		}


		//Check for violations of the preferenceForAllCandidates validator. That is violated if there isn't preferences for all candiates and it isn't a blank vote
		let preferenceForAllId = VoteValidator.preferenceForAllCandidates.id
		let preferenceForAll = await vote.validators.contains(where: {$0.id == preferenceForAllId})
		if Set(realOptions) != Set(await vote.options) && !realOptions.isEmpty && preferenceForAll{
			throw VotingDataError.allShouldBeFilledIn
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
		case .blankVotesNotAllowed:
			return "Blank votes are no allowed in this vote"
		}
	}
	
	case invalidRequest
	case invalidUserId
	case allShouldBeDifferent
	case attemptedToVoteMultipleTimes
	case allShouldBeFilledIn
	case blankVotesNotAllowed
}
