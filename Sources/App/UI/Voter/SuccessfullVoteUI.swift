import Foundation
struct SuccessfullVoteUI: UIManager{
    var version: String = App.version
    var title: String
	var voterID: String
	var priorities: [String]
	
	var buttons: [UIButton] = [.backToPlaza]
	var errorString: String? = nil
	
	static var template: String = "success"
}
