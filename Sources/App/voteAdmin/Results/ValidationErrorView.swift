import AltVoteKit
struct ValidationErrorView: Codable{
	var title: String
	var errorCount: Int
	var validationResults: [VoteValidationResult]
	
	init(title: String, validationResults: [VoteValidationResult]){
		self.title = title
		self.errorCount = validationResults.countErrors
		self.validationResults = validationResults
	}
}
