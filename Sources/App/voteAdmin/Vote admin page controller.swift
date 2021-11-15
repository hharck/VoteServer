import AltVoteKit
import Foundation
struct VoteAdminUIController: Codable{
	let title: String
	
	let voteLink: String
	
	let showGetResults: Bool
	let showClose: Bool
	let showOpen: Bool
	
	var headers = ["UserID", "Has voted", "Is allowed to vote"]
	private	let userStatus: [UserAndStatus]
	
	init?(votemanager: VoteManager, sessionID: UUID) async {
		
		guard
			let vote = await votemanager.voteFor(session: sessionID),
			let isOpen = await votemanager.statusFor(vote),
			let joinPhrase = await votemanager.getJoinPhraseFor(vote: vote)
		else {
			fatalError()
			//			return nil
		}
		
		
		let voteCount = await vote.votes.count
		
		
		self.title = await vote.name
		
		
		self.showGetResults = voteCount >= 2 && !isOpen
		self.showOpen = !isOpen
		self.showClose = isOpen
		
		
		
		var tempUsers = [UserID: UserAndStatus]()
		
		let votes = await vote.votes
		let voters = await vote.eligibleVoters
		votes.forEach { vote in
			tempUsers[vote.userID] = UserAndStatus(userID: vote.userID, hasVoted: true, isEligibleToVote: false)
		}
		
		voters.forEach { userID in
			if tempUsers[userID] != nil {
				tempUsers[userID]!.isEligibleToVote = true
			} else {
				tempUsers[userID] = UserAndStatus(userID: userID, hasVoted: false, isEligibleToVote: true)
			}
		}
		
		userStatus = tempUsers.map(\.value).sorted(by: { lhs, rhs in
			if lhs.isEligibleToVote == rhs.isEligibleToVote{
				return lhs.userID < rhs.userID
			} else {
				return lhs.isEligibleToVote
			}
		})
		voteLink = "/v/\(joinPhrase)"
	}
}

private struct UserAndStatus: Codable{
	let userID: UserID
	let hasVoted: Bool
	var isEligibleToVote: Bool
}


enum statusChange: String, Codable{
	case open, close, getResults
}
