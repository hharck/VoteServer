import AltVoteKit
struct ShowWinnerUI: Codable{
	internal init(title: String, winners: [VoteOption], numberOfVotes: Int, debug2: [[String]]? = nil) {
		self.title = title
		self.winners = winners
		
		hasMultipleWinners = winners.count != 1
		if debug2 != nil && !debug2!.isEmpty{
			self.showDebug = true
			self.debug2 = debug2!
			
			var max = 0
			debug2!.forEach{
				if $0.count > max{
					max = $0.count
				}
			}
			
			if max == 0 {
				self.db2Headers = []
			} else {
				self.db2Headers = (1...max).sorted()
			}
			
		} else {
			self.showDebug = false
			self.db2Headers = []
			self.debug2 = []
		}
		
		self.numberOfVotes = numberOfVotes //debug2.count
//		self.debug1 = debug1

	}
	
	var title: String
	var winners: [VoteOption]
	var hasMultipleWinners: Bool
	
	var numberOfVotes: Int
	
//	var debug1: [VoteOption: [Int:Int]]
	var debug2: [[String]]
	var showDebug: Bool
	
	var db2Headers: [Int]
	
	
}
