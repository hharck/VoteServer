import Foundation
struct SuccessfullVoteUI: UIManager{
	var title: String
	var voterID: String
	var priorities: [String]
	
	var buttons: [UIButton] = [.GroupOnly.backToPlaza]
	var errorString: String? = nil
	var generalInformation: HeaderInformation! = nil
	
	static var template: String = "success"
}
