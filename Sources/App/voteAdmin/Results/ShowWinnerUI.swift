import AltVoteKit
struct ShowWinnerUI: Codable{
	internal init(title: String, winners: [VoteOption], numberOfVotes: Int, enabledOptions: Set<VoteOption>, disabledOptions: Set<VoteOption>) {
		assert(enabledOptions.isDisjoint(with: disabledOptions), "ShowWinnerUI received the same option (\(enabledOptions.intersection(disabledOptions))) as enabled and disabled")
		
		self.title = title
		self.winners = winners
		
		self.enabledOptions = Array(enabledOptions).sorted(by: {$0.name<$1.name})
		self.disabledOptions = Array(disabledOptions).sorted(by: {$0.name<$1.name})

		self.hasEnabledAndDisabled = !enabledOptions.isEmpty && !disabledOptions.isEmpty

		self.numberOfVotes = numberOfVotes
		hasMultipleWinners = winners.count != 1
	}
	
	var title: String
	var winners: [VoteOption]
	var hasMultipleWinners: Bool
	
	var numberOfVotes: Int
	var enabledOptions: [VoteOption]
	var disabledOptions: [VoteOption]
	
	var hasEnabledAndDisabled: Bool
}
