import VoteKit
import AltVoteKit

struct AdminUIController: UITableManager{
	var title: String
	var errorString: String? = nil
	var generalInformation: HeaderInformation! = nil
	var hideIfEmpty: Bool = true
	
	var buttons: [UIButton] = [
		.reload,
		.init(uri: .createvote(AlternativeVote.shortName), text: "Create \"Alternative vote\"", color: .green),
		.init(uri: .createvote(SimpleMajority.shortName), text: "Create \"Simple majority vote\"", color: .green),
		.init(uri: .createvote(yesNoVote.shortName), text: "Create \"Yes/no vote\"", color: .green),
        .init(uri: "/admin/settings/", text: "Settings", color: .blue, inGroup: true),
		.init(uri: "/admin/constituents/", text: "Manage constituents", color: .blue, inGroup: true),
	]
	
	var rows = [SimplifiedVoteData]()
	var tableHeaders = [String]()
	
	var groupJoinLink: String
	
	init(for group: Group, settings: GroupSettings) async{
		self.title = group.name
		groupJoinLink = group.joinPhrase
		tableHeaders = ["Name", "Vote type", "No. of votes cast", "Open/closed"]
		for vote in await group.allVotes() {
			var status = await group.statusFor(vote)
			if status == nil{
				assertionFailure("Vote without status was found.")
				await group.setStatusFor(vote.id, to: .closed)
				status = .closed
			}
			
			// Workaround for compiler crash in Swift 5.7
			func addRow<V: DVoteProtocol>(vote: V) async {
				let newRow = await SimplifiedVoteData(name: vote.name, voteType: vote.shortName, isOpen: status == .open, totalVotesCast: vote.votes.count, voteID: vote.id.uuidString)
				rows.append(newRow)
			}
			
			await addRow(vote: vote)
		}

		rows.sort{ $0.name < $1.name }

		if settings.chatState != .disabled {
			self.buttons.append(UIButton(uri: "/admin/chats/", text: "Chats", color: .blue, inGroup: true))
		}
	}
	
	static var template: String = "admin"
}

//TODO: Merge with similar type for plaza
struct SimplifiedVoteData: Codable{
	
	let name: String
    let voteType: String
	let isOpen: Bool
	let totalVotesCast: Int
	let voteID: String
}
