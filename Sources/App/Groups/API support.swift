import VoteExchangeFormat
import VoteKit
extension Group {
	func getExchangeData(for constituentID: ConstituentIdentifier, constituentsCanSelfResetVotes: Bool) async -> GroupData{
        let voteData = await convertVotesToMetadata(self.allVotes(), constituentID: constituentID, group: self)
        return GroupData(name: self.name, availableVotes: voteData, canDeleteVotes: constituentsCanSelfResetVotes)
    }
}
