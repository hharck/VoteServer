import VoteExchangeFormat
import Vapor
import VoteKit

func convertVoteToMetadata(_ v: any DVoteProtocol, constituentID: ConstituentIdentifier, group: Group) async -> VoteMetadata{
    async let id = v.id
    async let name = v.name
    async let hasVoted = v.hasConstituentVoted(constituentID)
    let isOpen = await group.statusFor(await id) == .open
    
	return await VoteMetadata(id: id, name: name, kind: v.kind, isOpen: isOpen, hasVoted: hasVoted)
}

func convertVotesToMetadata(_ data: [any DVoteProtocol], constituentID: ConstituentIdentifier, group: Group) async -> Set<VoteMetadata>{
    var result = Set<VoteMetadata>()
    for v in data{
        result.insert(await convertVoteToMetadata(v, constituentID: constituentID, group: group))
    }
    return result
}


extension ExchangeOption{
    init(option: VoteOption){
        self.init(name: option.name, uuid: option.id)
    }
}

extension ExtendedVoteData{
	init(_ vote: some DVoteProtocol, constituentID: ConstituentIdentifier, group: Group) async{
        async let metadata = convertVoteToMetadata(vote, constituentID: constituentID, group: group)
        async let validatorKeys = vote.genericValidators.map(\.id) + vote.particularValidators.map(\.id)
		async let options = vote.options.map(ExchangeOption.init)
        self = ExtendedVoteData(metadata: await metadata, options: await options, validatorKeys: await validatorKeys)
    }
}

// Marks all datatypes from the API as 'Content' to allow an instance of these to be returned directly in a route
extension ExtendedVoteData: Content{}
extension GroupData: Content{}
extension VoteMetadata: Content{}
