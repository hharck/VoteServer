import Foundation
import Vapor
import VoteKit
import AltVoteKit

func votingRoutes(_ path: RoutesBuilder, groupsManager: GroupsManager) {
    
    /// Shows the voting ui for the supplied voteID
	path.get(use: getVote)
	func getVote(req: Request) async throws -> View{
		guard let (dbGroup, vote, user) = await voteGroupAndUserID(for: req) else{
			throw Redirect(.plaza)
		}
		let group = await groupsManager.groupForGroup(dbGroup)

		switch vote {
		case .alternative(let v):
			return try await checkAndShow(group: group, user: user, vote: v).render(for: req)
		case .yesno(let v):
			return try await checkAndShow(group: group, user: user, vote: v).render(for: req)
		case .simplemajority(let v):
			return try await checkAndShow(group: group, user: user, vote: v).render(for: req)
		}
		
		
	}
    
    /// Receives the vote the constituent wants to cast, and either accepts the vote or an error will be shown to the user
	path.post(use: postVote)
	func postVote(req: Request) async throws -> View {
        guard let (dbGroup, vote, user) = await voteGroupAndUserID(for: req) else{
			throw Redirect(.plaza)
        }
		
		let group = await groupsManager.groupForGroup(dbGroup)
        // Checks that the vote is open, otherwise the relevant votepage will be shown in the closed mode
        guard await group.statusFor(await vote.id()) == .open else {
            switch vote {
            case .alternative(let v):
				return try await AltVotePageGenerator.closed(title: v.name).render(for: req)
            case .yesno(let v):
                return try await YesNoVotePage.closed(title: v.name).render(for: req)
            case .simplemajority(let v):
                return try await SimMajVotePage.closed(title: v.name).render(for: req)
            }
        }
        
        switch vote {
        case .alternative(let v):
            return try await d(group: group, vote: v, user: user, req: req).render(for: req)
        case .yesno(let v):
            return try await d(group: group, vote: v, user: user, req: req).render(for: req)
        case .simplemajority(let v):
            return try await d(group: group, vote: v, user: user, req: req).render(for: req)
        }
    }
    
    
    /// Checks that a vote can be accessed and renders the vote page
    /// - Returns: The relevant vote page; either in a "Redy to vote state" or an error state
    func checkAndShow<V: SupportedVoteType>(group: Group, user: DBUser, vote: V, errorString: String? = nil, persistentData: V.VotePageUI.PersistanceData? = nil) async -> UIManager{
        //Checks that the vote is open
        guard await group.statusFor(vote) == .open  else {
            return await V.VotePageUI.closed(title: await vote.name)
        }
        
        // Checks that the user hasn't voted yet
		guard !(await vote.hasConstituentVoted(user.asConstituent())) else{
            return await V.VotePageUI.hasVoted(title: await vote.name)
        }
        
        // Creates a vote page for the given vote
        return await V.VotePageUI.init(title: await vote.name, vote: vote, errorString: errorString, persistentData: persistentData)
    }
    
    
    
    /// Returns a UI dependent on the success of decoding and storing votes
    /// - Returns: The UI to show, either a vote page where the constituent can try to fix the error or a success page which shows what was voted for
    func d<V: SupportedVoteType>(group: Group, vote: V, user: DBUser, req: Request) async -> UIManager{
		let constituent = user.asConstituent()
		
        let p: ((data: V.ReceivedData?, error: Error)?, [String]?) = await decodeAndStore(group: group, vote: vote, constituent: constituent, req: req)
        assert(p.0 == nil || p.1 == nil)
        
        
        if let confirmationStrings = p.1{
            let voterID = constituent.getNameOrId()
            return SuccessfullVoteUI(title: await vote.name, voterID: voterID, priorities: confirmationStrings )
        } else {
            let votePage = await checkAndShow(group: group, user: user, vote: vote, errorString: p.0?.error.asString(), persistentData: p.0?.data?.asCorrespondingPersistenseData())
            return votePage
        }
    }
    
    
    
    func voteGroupAndUserID(for req: Request) async -> (group: DBGroup, vote: VoteTypes, constituent: DBUser)?{
        guard
			let user = req.auth.get(DBUser.self),
			let dbGroup = req.auth.get(DBGroup.self),
            let voteIDStr = req.parameters.get("voteID"),
            let vote = await groupsManager.groupForGroup(dbGroup).voteForID(voteIDStr)
        else {
            return nil
        }
        
        return (dbGroup, vote, user)
    }
}
