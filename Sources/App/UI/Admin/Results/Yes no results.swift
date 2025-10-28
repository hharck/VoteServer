import VoteKit
struct YesNoResultsUI: UITableManager {

    var numberOfVotes: Int

    var title: String

    var errorString: String?
    var buttons: [UIButton] = [.backToAdmin]

    static let template: String = "results/yesno"

    var tableHeaders: [String] = ["Name", "Yes", "No"]  // The "Blank" column is only added if the vote allows for it
    var showBlank: Bool = false

    var rows: [Row]

    init(vote: YesNoVote, count: [VoteOption: (yes: UInt, no: UInt, blank: UInt)]) async {
        self.title = await vote.name
        self.numberOfVotes = await vote.votes.count

        // Adds the "Blank" column
        if await !vote.genericValidators.contains(.noBlankVotes) {
            tableHeaders.append("Blank")
            showBlank = true
        }

        self.rows = await vote.options.map { opt in
            if let count = count[opt] {
                return Row(name: opt.name, yesCount: count.yes, noCount: count.no, blankCount: count.blank)
            } else {
                return Row(name: opt.name, yesCount: 0, noCount: 0, blankCount: 0)
            }
        }
    }

    struct Row: Codable {

        var name: String
        var yesCount: UInt
        var noCount: UInt
        var blankCount: UInt
    }

}
