import VoteExchangeFormat
import Vapor
import VoteKit

func convertVoteToMetadata<V: SupportedVoteType>(_ v: V, constituentID: ConstituentIdentifier, group: Group) async -> VoteMetadata{
    async let id = v.id
    async let name = v.name
    async let hasVoted = v.hasConstituentVoted(constituentID)
    let isOpen = await group.statusFor(await id) == .open
    let kind: VoteMetadata.Kind = .AlternativeVote
    
    return VoteMetadata(id: await id, name: await name, kind: kind, isOpen: isOpen, hasVoted: await hasVoted)
}

func convertVotesToMetadata<V: SupportedVoteType>(_ data: [V], constituentID: ConstituentIdentifier, group: Group) async -> Set<VoteMetadata>{
    var result = Set<VoteMetadata>()
    for v in data{
        result.insert(await convertVoteToMetadata(v, constituentID: constituentID, group: group))
    }
    return result
}


extension Data: AsyncResponseEncodable {
    public func encodeResponse(for request: Request) async throws -> Response {
        try await Response(body: .init(data: self)).encodeResponse(for: request)
    }
}

extension ExtendedVoteData{
    init<V: SupportedVoteType>(_ v: V, constituentID: ConstituentIdentifier, group: Group) async{
        async let metadata = convertVoteToMetadata(v,constituentID: constituentID, group: group)
        async let validatorKeys = v.genericValidators.map(\.name) + v.particularValidators.map(\.name)
        async let options = v.options.map(\.name)
        self = ExtendedVoteData(metaData: await metadata , options: await options, validatorKeys: await validatorKeys)
    }
    
}


extension ExtendedVoteData: Content{}
extension GroupData: Content{}
extension VoteMetadata: Content{}
