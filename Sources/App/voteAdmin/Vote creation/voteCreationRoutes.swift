import Vapor
import VoteKit
import AltVoteKit
func voteCreationRoutes(_ app: Application, groupsManager: GroupsManager) {
    /// Shows admins a page which'' let them create the kind of vote supplied in the "type" parameter
    app.get("createvote", ":type", use: createVote)
	app.post("createvote", ":type", use: createVote)
    @Sendable func createVote(req: Request) async -> ResponseOrRedirect<VoteCreatorUI> {
		guard
			let sessionID = req.session.authenticated(AdminSession.self),
			let group = await groupsManager.groupForSession(sessionID)
		else {
            return .redirect(.create)
		}
		guard let parameter = req.parameters.get("type"), let type = VoteTypes.StringStub(rawValue: parameter) else {
            return .redirect(.admin)
		}

		if req.method == .POST {
            // Attempt to create a vote for the request
            do {
                let voteHTTPData = try req.content.decode(VoteCreationReceivedData.self)

                async let constituents = group.verifiedConstituents.union(await group.unverifiedConstituents)

                // Validates the data and generates a Vote object
                do {
                    let title = try voteHTTPData.getTitle()
                    let options = try voteHTTPData.getOptions(type: type.type)

                    switch type {
                    case .alternative:
                        let vote = AlternativeVote(
                            name: title,
                            options: options,
                            constituents: await constituents,
                            tieBreakingRules: [TieBreaker.dropAll, TieBreaker.removeRandom, TieBreaker.keepRandom],
                            genericValidators: voteHTTPData.getGenValidators(),
                            customValidators: voteHTTPData.getCustomValidators()
                        )
                        await group.addVoteToGroup(vote: vote)
                    case .yesNo:
                        let vote = YesNoVote(
                            name: title,
                            options: options,
                            constituents: await constituents,
                            genericValidators: voteHTTPData.getGenValidators(),
                            customValidators: voteHTTPData.getCustomValidators()
                        )
                        await group.addVoteToGroup(vote: vote)
                    case .simpleMajority:
                        let vote = SimpleMajority(
                            name: title,
                            options: options,
                            constituents: await constituents,
                            genericValidators: voteHTTPData.getGenValidators()
                        )
                        await group.addVoteToGroup(vote: vote)
                    }

                    return .redirect(.admin)
                } catch {
                    return .response(
                        VoteCreatorUI(
                            typeName: type.type.typeName,
                            errorString: error.asString(),
                            validatorsGeneric: type.type.genericValidatorData,
                            validatorsCustom: type.type.customValidatorData,
                            voteHTTPData
                        )
                    )
                }
            } catch {
                return .response(
                    VoteCreatorUI(
                        typeName: type.type.typeName,
                        errorString: error.asString(),
                        validatorsGeneric: type.type.genericValidatorData,
                        validatorsCustom: type.type.customValidatorData,
                        nil
                    )
                )
            }

        } else {
            return .response(
                VoteCreatorUI(
                    typeName: type.type.typeName,
                    errorString: nil,
                    validatorsGeneric: type.type.genericValidatorData,
                    validatorsCustom: type.type.customValidatorData
                )
            )
        }
    }
}

struct ValidatorData: Codable {
    var id: String
    var name: String
    var isEnabled: Bool
    var stack: ValidatorStacks

    init<V: VoteStub>(type: ValidatorStacks, validator: any Validateable<V>, isEnabled: Bool = false) {
        self.name = validator.name
        self.id = validator.id
        self.isEnabled = isEnabled
        self.stack = type
    }

    enum ValidatorStacks: String, Codable {
        case genericValidators
        case customValidators
    }
}
