import VoteKit
import Foundation
struct ValidationErrorUI: UIManager{
    var title: String
    var errorCount: Int
    var buttons: [UIButton]
    var validationResults: [VoteValidationResult]
    var errorString: String? = nil
    static let template: String = "validators failed"
    
    init(title: String, validationResults: [VoteValidationResult], voteID: UUID){
        self.title = title
        self.errorCount = validationResults.map(\.errors.count).reduce(0, +)
        self.validationResults = validationResults
        
        
        self.buttons = [.init(uri: "/results/\(voteID.uuidString)?force=1", text: "Force count", color: .red, lockable: true)]
    }
}
