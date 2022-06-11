import VoteKit
import Foundation
struct ValidationErrorUI: UIManager{
	
	var title: String
	var errorCount: Int
	var buttons: [UIButton]
	var validationResults: [VoteValidationResult]
	var errorString: String? = nil
	var generalInformation: HeaderInformation! = nil
	static var template: String = "validators failed"

	init(title: String, validationResults: [VoteValidationResult], groupID: UUID, voteID: UUID){
		self.title = title
		self.errorCount = validationResults.countErrors
		self.validationResults = validationResults
		
		
		self.buttons = [.init(uri: "group/\(groupID)/results/\(voteID.uuidString)?force=1", text: "Force count", color: .red, lockable: true, inGroup: true)]
	}
}
