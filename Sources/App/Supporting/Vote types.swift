import VoteKit
import AltVoteKit
import Foundation
import VoteExchangeFormat

enum VoteTypes {
    case alternative(AlternativeVote)
    case yesno(YesNoVote)
    case simplemajority(SimpleMajority)

    enum StringStub: String {
        case alternative = "alternativevote"
        case yesNo = "yesno"
        case simpleMajority = "simplemajority"

        init(_ voteTypes: VoteTypes) {
            switch voteTypes {
            case .alternative:
                self = .alternative
            case .yesno:
                self = .yesNo
            case .simplemajority:
                self = .simpleMajority
            }
        }

        var type: any SupportedVoteType.Type {
            switch self {
            case .alternative: AlternativeVote.self
            case .yesNo: YesNoVote.self
            case .simpleMajority: SimpleMajority.self
            }
        }
    }

    init<V: SupportedVoteType>(vote: V) {
        switch V.enumCase {
        case .alternative:
            // swiftlint:disable:next force_cast
            self = .alternative(vote as! AlternativeVote)
        case .yesNo:
            // swiftlint:disable:next force_cast
            self = .yesno(vote as! YesNoVote)
        case .simpleMajority:
            // swiftlint:disable:next force_cast
            self = .simplemajority(vote as! SimpleMajority)
        }
    }

    func asStub() -> StringStub {
        StringStub(self)
    }

    var asVoteProtocol: any SupportedVoteType {
        switch self {
        case .alternative(let alternativeVote): alternativeVote
        case .yesno(let yesNoVote): yesNoVote
        case .simplemajority(let simpleMajority): simpleMajority
        }
    }
}

extension VoteTypes {
    func id() async -> UUID {
        switch self {
        case .alternative(let v):
            return await v.id
        case .yesno(let v):
            return await v.id
        case .simplemajority(let v):
            return await v.id
        }
    }

    func name() async -> String {
        switch self {
        case .alternative(let v):
            return await v.name
        case .yesno(let v):
            return await v.name
        case .simplemajority(let v):
            return await v.name
        }
    }

    func constituents() async -> Set<Constituent> {
        switch self {
        case .alternative(let v):
            return await v.constituents
        case .yesno(let v):
            return await v.constituents
        case .simplemajority(let v):
            return await v.constituents
        }
    }

    func options() async -> [VoteOption] {
        switch self {
        case .alternative(let v):
            return await v.options
        case .yesno(let v):
            return await v.options
        case .simplemajority(let v):
            return await v.options
        }
    }
}

/// Adds the types associated with each kind of vote
protocol SupportedVoteType: VoteProtocol {
    associatedtype ReceivedData: VotingData where ReceivedData.Vote == Self
    associatedtype VotePageUI: VotePage where VotePageUI.VoteType == Self
    static var enumCase: VoteTypes.StringStub {get}
    static var minimumRequiredOptions: Int {get}
    static var genericValidatorData: [ValidatorData] {get}
    static var customValidatorData: [ValidatorData] {get}
}
extension SupportedVoteType {
    static var genericValidatorData: [ValidatorData] {
        GenericValidator<Self.VoteType>
            .allValidators
            .map {
                ValidatorData(type: .genericValidators, validator: $0, isEnabled: false)
            }
    }
}
extension SupportedVoteType where Self: HasCustomValidators {
    static var customValidatorData: [ValidatorData] {
        Self.CustomValidators.allValidators.map {
            ValidatorData(type: .customValidators, validator: $0, isEnabled: false)
        }
    }
}

extension AlternativeVote: SupportedVoteType {
    typealias ReceivedData = AltVotingData
    typealias PersistanceData = AltVotingData
    typealias VotePageUI = AltVotePageGenerator
    static let enumCase: VoteTypes.StringStub = .alternative
    static let minimumRequiredOptions: Int = 2
}

extension YesNoVote: SupportedVoteType {
    typealias ReceivedData = YnVotingData
    typealias PersistanceData = [UUID: Bool]
    typealias VotePageUI = YesNoVotePage
    static let enumCase: VoteTypes.StringStub = .yesNo
    static let minimumRequiredOptions: Int = 1
}

extension SimpleMajority: SupportedVoteType {
    typealias ReceivedData = SimpleMajorityVotingData
    typealias PersistanceData = UUID
    typealias VotePageUI = SimMajVotePage
    static let enumCase: VoteTypes.StringStub = .simpleMajority
    static let minimumRequiredOptions: Int = 2
    static let customValidatorData: [ValidatorData] = []
}
