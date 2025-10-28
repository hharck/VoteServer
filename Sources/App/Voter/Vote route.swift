import Foundation
import Vapor
import VoteKit
import AltVoteKit

func votingRoutes(_ app: Application, groupsManager: GroupsManager) {

    /// Shows the voting ui for the supplied voteID
	app.get("vote", ":voteID", use: getVote)
    @Sendable func getVote(req: Request) async throws -> ResponseOrRedirect<View> {
		guard let (group, vote, constituent) = await voteGroupAndUserID(for: req) else {
            return .redirect(.plaza)
		}
        let ui: UIManager = switch vote {
		case .alternative(let v):
            await checkAndShow(group: group, constituent: constituent, vote: v)
		case .yesno(let v):
            await checkAndShow(group: group, constituent: constituent, vote: v)
		case .simplemajority(let v):
            await checkAndShow(group: group, constituent: constituent, vote: v)
		}
        return try await .response(ui.render(for: req))

	}

    /// Receives the vote the constituent wants to cast, and either accepts the vote or an error will be shown to the user
	app.post("vote", ":voteID", use: postVote)
    @Sendable func postVote(req: Request) async throws -> ResponseOrRedirect<View> {
        guard let (group, vote, constituent) = await voteGroupAndUserID(for: req) else {
            return .redirect(.plaza)
        }

        // Checks that the vote is open, otherwise the relevant votepage will be shown in the closed mode
        guard await group.statusFor(await vote.id()) == .open else {
            let view: UIManager = switch vote {
            case .alternative(let v):
				await AltVotePageGenerator.closed(title: v.name)
            case .yesno(let v):
                await YesNoVotePage.closed(title: v.name)
            case .simplemajority(let v):
                await SimMajVotePage.closed(title: v.name)
            }
            return try await .response(view.render(for: req))
        }

        switch vote {
        case .alternative(let v):
            return try await .response(d(group: group, vote: v, constituent: constituent, req: req).render(for: req))
        case .yesno(let v):
            return try await .response(d(group: group, vote: v, constituent: constituent, req: req).render(for: req))
        case .simplemajority(let v):
            return try await .response(d(group: group, vote: v, constituent: constituent, req: req).render(for: req))
        }
    }

    /// Checks that a vote can be accessed and renders the vote page
    /// - Returns: The relevant vote page; either in a "Redy to vote state" or an error state
    @Sendable func checkAndShow<V: SupportedVoteType>(group: Group, constituent: Constituent, vote: V, errorString: String? = nil, persistentData: V.VotePageUI.PersistanceData? = nil) async -> V.VotePageUI {
        // Checks that the vote is open
        guard await group.statusFor(vote) == .open  else {
            return await V.VotePageUI.closed(title: await vote.name)
        }

        // Checks that the user hasn't voted yet
        guard !(await vote.hasConstituentVoted(constituent)) else {
            return await V.VotePageUI.hasVoted(title: await vote.name)
        }

        // Creates a vote page for the given vote
        return await V.VotePageUI.init(title: await vote.name, vote: vote, errorString: errorString, persistentData: persistentData)
    }

    /// Returns a UI dependent on the success of decoding and storing votes
    /// - Returns: The UI to show, either a vote page where the constituent can try to fix the error or a success page which shows what was voted for
    @Sendable func d<V: SupportedVoteType>(group: Group, vote: V, constituent: Constituent, req: Request) async throws(Abort) -> UIManager {
        let p: ((data: V.ReceivedData?, error: Error)?, [String]?) = try await decodeAndStore(group: group, vote: vote, constituent: constituent, req: req)
        assert(p.0 == nil || p.1 == nil)

        if let confirmationStrings = p.1 {
            let voterID = constituent.getNameOrId()
            return SuccessfullVoteUI(title: await vote.name, voterID: voterID, priorities: confirmationStrings )
        } else {
            let votePage = await checkAndShow(group: group, constituent: constituent, vote: vote, errorString: p.0?.error.asString(), persistentData: p.0?.data?.asCorrespondingPersistenseData())
            return votePage
        }
    }

    @Sendable func voteGroupAndUserID(for req: Request) async -> (group: Group, vote: VoteTypes, constituent: Constituent)? {
        guard
            let voterSession = req.session.authenticated(VoterSession.self),
            let groupID = req.session.authenticated(GroupSession.self),
            let voteIDStr = req.parameters.get("voteID"),
            let group = await groupsManager.groupForGroupID(groupID),
            let constituent = await group.constituentsSessionID[voterSession],
            let vote = await group.voteForID(voteIDStr)
        else {
            return nil
        }

        return (group, vote, constituent)
    }
}
