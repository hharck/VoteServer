import Foundation
struct SuccessfullVoteUI: UIManager{
	var title: String
	var voterID: String
	var priorities: [String]
	
	var buttons: [UIButton] = [.backToPlaza]
	var errorString: String? = nil
	
	static var template: String = "success"
}
