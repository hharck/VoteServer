import Foundation
import AltVoteKit
struct PlazaUI: UITableManager{
	internal init(errorString: String? = nil, constituent: Constituent, group: Group) async {
		self.errorString = errorString
		self.name = constituent.name ?? constituent.identifier
		self.groupName = group.name
		
		
		for vote in await group.allVotes() {
			let hasVoted = await vote.hasConstituentVoted(constituent)
			guard let status = await group.statusFor(vote) else {
				continue
			}
			
			await rows.append(VoteListElement(voteID: vote.id, name: vote.name, isOpen: status == .open, hasVoted: hasVoted))
		}
		rows.sort(by: {$0.name < $1.name})
	}
	
	var title: String = "Plaza"
	var errorString: String? = nil
	
	var buttons: [UIButton] = [.reload]
	
	var tableHeaders: [String] = ["Name", "Type", "Open", "Voted"]
	
	var rows: [VoteListElement] = []
	
	var name: String
	var groupName: String
	
	static var template: String = "plaza"
	
	struct VoteListElement: Codable{
		internal init(voteID: UUID, name: String, isOpen: Bool, hasVoted: Bool) {
			self.voteID = voteID
			self.name = name
			self.isOpen = isOpen
			self.hasVoted = hasVoted
			self.showLink = isOpen && !hasVoted
		}
		
		let voteID: UUID
		let name: String
		let isOpen: Bool
		let hasVoted: Bool
		let showLink: Bool
	}
}

