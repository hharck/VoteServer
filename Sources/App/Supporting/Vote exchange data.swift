import VoteExchangeFormat
import Vapor
import VoteKit

func convertVoteToMetadata<V: SupportedVoteType>(_ v: V, constituentID: ConstituentIdentifier, group: Group) async -> VoteMetadata {
    async let id = v.id
    async let name = v.name
    async let hasVoted = v.hasConstituentVoted(constituentID)
    let isOpen = await group.statusFor(await id) == .open

    let kind: VoteMetadata.Kind
    switch V.enumCase {
    case .alternative:
        kind = .AlternativeVote
    case .simpleMajority:
        kind = .SimMajVote
    case .yesNo:
        kind = .YNVote
    }

    return VoteMetadata(id: await id, name: await name, kind: kind, isOpen: isOpen, hasVoted: await hasVoted)
}

func convertVotesToMetadata<V: SupportedVoteType>(_ data: [V], constituentID: ConstituentIdentifier, group: Group) async -> Set<VoteMetadata> {
    var result = Set<VoteMetadata>()
    for v in data {
        result.insert(await convertVoteToMetadata(v, constituentID: constituentID, group: group))
    }
    return result
}

extension ExchangeOption {
    init(option: VoteOption) {
        self.init(name: option.name, uuid: option.id)
    }
}

extension ExtendedVoteData {
    init<V: SupportedVoteType>(_ v: V, constituentID: ConstituentIdentifier, group: Group) async {
        async let metadata = convertVoteToMetadata(v, constituentID: constituentID, group: group)
        async let validatorKeys = v.allValidators.map(\.id)
		async let options = v.options.map(ExchangeOption.init)
        self = ExtendedVoteData(metadata: await metadata, options: await options, validatorKeys: await validatorKeys)
    }
}

// Marks all datatypes from the API as 'Content' to allow an instance of these to be returned directly in a route
extension ExtendedVoteData: @retroactive Content {}
extension GroupData: @retroactive Content {}
extension VoteMetadata: @retroactive Content {}
