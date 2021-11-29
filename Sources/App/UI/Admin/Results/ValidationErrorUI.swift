import AltVoteKit
import Foundation
struct ValidationErrorUI: UIManager{
	
	var title: String
	var errorCount: Int
	var buttons: [UIButton]
	var validationResults: [VoteValidationResult]
	var errorString: String? = nil
	static var template: String = "validators failed"

	init(title: String, validationResults: [VoteValidationResult], voteID: UUID){
		self.title = title
		self.errorCount = validationResults.countErrors
		self.validationResults = validationResults
		
		
		self.buttons = [.init(uri: "/results/\(voteID.uuidString)?force=1", text: "Force count", color: .red, lockable: true)]
	}
}
