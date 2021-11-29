import AltVoteKit
import Foundation
struct AdminUIController: UITableManager{
	var title: String
	var errorString: String? = nil
	
	var buttons: [UIButton] = [
		.reload,
		.init(uri: .createvote, text: "Create vote", color: .green),
		.init(uri: "/voteadmin/constituents/", text: "Manage constituents", color: .blue)
	]
	
	var rows = [SimplifiedVoteData]()
	var tableHeaders = [String]()
	
	var groupJoinLink: String
	
	init(for group: Group) async{
		self.title = group.name
		groupJoinLink = group.joinPhrase
		tableHeaders = ["Name", "No. of votes cast", "Open/closed"]
		
		let votes = await group.allVotes()
		for vote in votes {
			guard let status = await group.statusFor(vote) else{
				assertionFailure("Vote without status was found.")
				continue
			}
			
			await rows.append(SimplifiedVoteData(name: vote.name, isOpen: status == .open, totalVotesCast: await vote.votes.count, voteID: await vote.id.uuidString))
			
		}
		rows.sort{ $0.name < $1.name}
	}
	
	static var template: String = "admin"
}


struct SimplifiedVoteData: Codable{
	
	let name: String
	let isOpen: Bool
	let totalVotesCast: Int
	let voteID: String
}
