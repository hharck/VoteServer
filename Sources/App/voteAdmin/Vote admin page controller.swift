import AltVoteKit
struct VoteAdminUIController: Codable{
	let title: String
	
	let showGetResults: Bool
	let showClose: Bool
	let showOpen: Bool
	
	var headers = ["UserID", "Has voted", "Was allowed to vote"]
	private	let userStatus: [UserAndStatus]
	
	init(title: String, showGetResults: Bool, showClose: Bool, showOpen: Bool, allUsers: [UserID], allVotes: [SingleVote]){
		self.title = title
		self.showGetResults = showGetResults
		self.showOpen = showOpen
		self.showClose = showClose
		
		
		
		var tempUsers = [UserID: UserAndStatus]()
		
		allVotes.forEach { vote in
			tempUsers[vote.userID] = UserAndStatus(userID: vote.userID, hasVoted: true, isEligibleToVote: false)
		}
		
		allUsers.forEach { userID in
			if tempUsers[userID] != nil {
				tempUsers[userID]!.isEligibleToVote = true
			} else {
				tempUsers[userID] = UserAndStatus(userID: userID, hasVoted: false, isEligibleToVote: true)
			}
		}
		
		userStatus = tempUsers.map(\.value)
		
	}
}

private struct UserAndStatus: Codable{
	let userID: UserID
	let hasVoted: Bool
	var isEligibleToVote: Bool
}
