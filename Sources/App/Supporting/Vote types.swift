import VoteKit
import AltVoteKit
import VoteExchangeFormat

extension VoteProtocol {
	static var shortName: String { Self.typeName.lowercased().replacingOccurrences(of: " ", with: "-") }
	var longName: String { Self.typeName }
	var shortName: String { Self.shortName }
	static var minimumRequiredOptions: Int {
		switch kind {
			case .YNVote:
				return 1
			case .SimMajVote, .AlternativeVote:
				return 2
		}
	}
	
	static var kind: VoteMetadata.Kind {
		switch shortName {
			case "yes-no":
				return .YNVote
			case "simple-majority":
				return .SimMajVote
			case "alternative-vote":
				return .AlternativeVote
			default:
				fatalError("Unknown vote type: \(shortName)")
		}
	}
	var kind: VoteMetadata.Kind { Self.kind }
	
}

protocol DVoteProtocol: VoteProtocol {
	associatedtype VotePageUI: VotePage where VotePageUI.VoteType == Self
	associatedtype ReceivedData: VotingData where ReceivedData.Vote == Self, ReceivedData.PersistenceData == VotePageUI.PersistenceData
}

extension AlternativeVote: DVoteProtocol {
	typealias VotePageUI = AltVotePageGenerator
	typealias ReceivedData = AltVotingData

}
extension SimpleMajority: DVoteProtocol {
	typealias VotePageUI = SimMajVotePage
	typealias ReceivedData = SimpleMajorityVotingData

}
extension yesNoVote: DVoteProtocol {
	typealias VotePageUI = YesNoVotePage
	typealias ReceivedData = YnVotingData

}
