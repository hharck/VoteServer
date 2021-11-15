import AltVoteKit
import Foundation
struct VoteAdminUIController: Codable{
	let title: String
	
	let voteLink: String
	
	let showGetResults: Bool
	let showClose: Bool
	let showOpen: Bool
	
	var headers = ["User id", "Name", "Has voted", "Is allowed to vote"]
	let userStatus: [UserAndStatus]
	
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
		
		
		
		var tempUsers = [Constituent: UserAndStatus]()
		
		let votes = await vote.votes
		let voters = await vote.eligibleVoters
		
		print(voters)
		votes.forEach { vote in
			tempUsers[vote.user] = UserAndStatus(user: vote.user, hasVoted: true, isEligibleToVote: false)
		}
		
		voters.forEach { user in
			if tempUsers[user] != nil {
				tempUsers[user]!.isEligibleToVote = true
			} else {
				tempUsers[user] = UserAndStatus(user: user, hasVoted: false, isEligibleToVote: true)
			}
		}
		
		userStatus = tempUsers.map(\.value).sorted(by: { lhs, rhs in
			if lhs.isEligibleToVote == rhs.isEligibleToVote{
				return lhs.user.identifier < rhs.user.identifier
			} else {
				return lhs.isEligibleToVote
			}
		})
		print(userStatus)
		voteLink = "/v/\(joinPhrase)"
	}
}

struct UserAndStatus: Codable{
	internal init(user: Constituent, hasVoted: Bool, isEligibleToVote: Bool) {
		self.user = user
		if self.user.name == nil{
			self.user.name = self.user.identifier
		}
		self.hasVoted = hasVoted
		self.isEligibleToVote = isEligibleToVote
	}
	
	var user: Constituent
	var hasVoted: Bool
	var isEligibleToVote: Bool
}


enum statusChange: String, Codable{
	case open, close, getResults
}
