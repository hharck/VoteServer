import VoteExchangeFormat
import VoteKit
extension Group{

	func getExchangeData(for constituentID: ConstituentIdentifier, constituentsCanSelfResetVotes: Bool) async -> GroupData{
        let (alt, yn, simMaj) = self.allVotes()

        async let altData = convertVotesToMetadata(alt, constituentID: constituentID, group: self)
        async let ynData = convertVotesToMetadata(yn, constituentID: constituentID, group: self)
        async let simMajData = convertVotesToMetadata(simMaj, constituentID: constituentID, group: self)
        
        let voteData = await altData.union(ynData).union(simMajData)

        
        return GroupData(name: self.name, availableVotes: voteData, canDeleteVotes: constituentsCanSelfResetVotes)
    }
}
