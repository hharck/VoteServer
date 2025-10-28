import VoteExchangeFormat
import VoteKit
extension Group {

    func getExchangeData(for constituentID: ConstituentIdentifier) async -> GroupData? {
        guard joinedConstituentsByID[constituentID] != nil else {
            return nil
        }

        let (alt, yn, simMaj) = self.allVotes()

        async let altData = convertVotesToMetadata(alt, constituentID: constituentID, group: self)
        async let ynData = convertVotesToMetadata(yn, constituentID: constituentID, group: self)
        async let simMajData = convertVotesToMetadata(simMaj, constituentID: constituentID, group: self)

        let voteData = await altData.union(ynData).union(simMajData)

        return GroupData(name: self.name, availableVotes: voteData, canDeleteVotes: self.settings.constituentsCanSelfResetVotes)
    }
}

// MARK: Password reset
extension Group {
	func setPasswordTo(digest: String) {
		self.passwordDigest = digest
	}
}
