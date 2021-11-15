import AltVoteKit
struct VotePageGenerator: Codable{
	var title: String
	var numbers: [Int]
	var options: [VoteOption]
	var errorString: String
	var hideUI: Bool = false
	
	init(title: String, options: [VoteOption], errorString: String = ""){
		self.title = title
		self.numbers = options.count == 0 ? [] : Array((1...options.count))
		self.options = options
		self.errorString = errorString
	}
	
	init(title: String){
		self.title = title
		self.numbers = []
		self.options = []
		self.errorString = "Vote is currently closed"
		hideUI = true
	}
}








