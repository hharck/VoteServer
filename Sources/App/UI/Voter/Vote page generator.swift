import AltVoteKit
import Foundation
struct AltVotePageGenerator: UIManager{
	var title: String
	var numbers: [PriorityData]
	var options: [VoteOption]
	var errorString: String?
	var hideUI: Bool = false
	var canVoteBlank: Bool
	var buttons: [UIButton] = []
	
	init(title: String, vote: AltVote?, errorString: String? = nil, _ persistentData: AltVotingData? = nil) async {
		
		if let options = await vote?.options {
			assert(options.count != 0 || errorString != nil)

			
			let noBlanks = VoteValidator.noBlankVotes.id
			canVoteBlank = await !vote!.validators.contains(where: {$0.id == noBlanks})
			
			
			if let priorities = persistentData?.priorities{
				self.numbers = options.count == 0 ? [] : (1...options.count).map({PriorityData(number: $0, selected: priorities[$0] ?? "default")})
			} else {
				self.numbers = options.count == 0 ? [] : (1...options.count).map({PriorityData(number: $0)})
			}
			self.options = options

		} else {
			self.canVoteBlank = false

			self.options = []
			self.numbers = []
		}
		
		
		self.title = title
		self.errorString = errorString
		
		
	}
	
	static func closed(title: String) async -> Self{
		var closedVPG = await self.init(title: title, vote: nil, errorString: "Vote is currently closed")
		closedVPG.hideUI = true
		closedVPG.buttons = [.backToPlaza]
		return closedVPG
	}
	
	static func hasVoted(title: String) async -> Self{
		var hasVotedVPG = await self.init(title: title, vote: nil, errorString: "You have already voted once, ask the admin to reset your vote")
		hasVotedVPG.hideUI = true
		return hasVotedVPG
	}
	
	static var template: String = "vote"
	
	struct PriorityData: Codable{
		internal init(number: Int, selected: String = "default") {
			self.number = number
			self.selected = selected
		}
		
		let number: Int
		let selected: String
	}
}




