import Foundation
import Vapor
import VoteKit
import AltVoteKit

func votingRoutes(_ path: RoutesBuilder, groupsManager: GroupsManager) {
    
    /// Shows the voting ui for the supplied voteID
	path.get(use: getVote)
	func getVote(req: Request) async throws -> View{
		guard let (dbGroup, vote, user) = await voteGroupAndUserID(for: req) else {
			throw Redirect(.plaza)
		}
		let group = await groupsManager.groupForGroup(dbGroup)

		func wrapper(_ vote: some DVoteProtocol) async -> UIManager {
			await checkAndShow(group: group, user: user, vote: vote)
		}
		return try await wrapper(vote).render(for: req)
	}
    
    /// Receives the vote the constituent wants to cast, and either accepts the vote or an error will be shown to the user
	path.post(use: postVote)
	func postVote(req: Request) async throws -> View {
        guard let (dbGroup, vote, user) = await voteGroupAndUserID(for: req) else{
			throw Redirect(.plaza)
        }
		
		let group = await groupsManager.groupForGroup(dbGroup)
      

		// Changes the vote from any to a concrete vote
		func wrapper<V: DVoteProtocol>(_ vote: V) async -> UIManager {
			// Checks that the vote is open, otherwise the relevant votepage will be shown in the closed mode
			guard await group.statusFor(await vote.id) == .open else {
				return await V.VotePageUI.closed(title: await vote.name)
			}
			
			let constituent = user.asConstituent()
			
			let p: ((data: V.ReceivedData?, error: Error)?, [String]?) = await decodeAndStore(group: group, vote: vote, constituent: constituent, req: req)
			assert(p.0 == nil || p.1 == nil)
			
			
			if let confirmationStrings = p.1{
				let voterID = constituent.getNameOrId()
				return SuccessfullVoteUI(title: await vote.name, voterID: voterID, priorities: confirmationStrings )
			} else {
				return await checkAndShow(group: group, user: user, vote: vote, errorString: p.0?.error.asString(), persistentData: p.0?.data?.asCorrespondingPersistenceData())
			}
		}
		
		return try await wrapper(vote).render(for: req)
	}
    
    /// Checks that a vote can be accessed and renders the vote page
    /// - Returns: The relevant vote page; either in a "Redy to vote state" or an error state
    func checkAndShow<V: DVoteProtocol>(group: Group, user: DBUser, vote: V, errorString: String? = nil, persistentData: V.ReceivedData.PersistenceData? = nil) async -> V.VotePageUI {
        //Checks that the vote is open
        guard await group.statusFor(vote) == .open  else {
            return await .closed(title: await vote.name)
        }
        
        // Checks that the user hasn't voted yet
		guard !(await vote.hasConstituentVoted(user.asConstituent())) else{
            return await .hasVoted(title: await vote.name)
        }
        
        // Creates a vote page for the given vote
        return await .init(title: await vote.name, vote: vote, errorString: errorString, persistentData: persistentData)
    }
    
    func voteGroupAndUserID(for req: Request) async -> (group: DBGroup, vote: any DVoteProtocol, constituent: DBUser)?{
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
