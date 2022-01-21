import Foundation
import Vapor
import VoteKit
import AltVoteKit

func votingRoutes(_ app: Application, groupsManager: GroupsManager) {
    
    /// Shows the voting ui for the supplied voteID
    app.get("vote", ":voteID") { req async throws -> Response in
        guard let (group, vote, constituent) = await voteGroupAndUserID(for: req) else{
            return req.redirect(to: .plaza)
        }
        switch vote {
        case .alternative(let v):
            return try await checkAndShow(group: group, constituent: constituent, vote: v).encodeResponse(for: req)
        case .yesno(let v):
            return try await checkAndShow(group: group, constituent: constituent, vote: v).encodeResponse(for: req)
        case .simplemajority(let v):
            return try await checkAndShow(group: group, constituent: constituent, vote: v).encodeResponse(for: req)
        }
        
    }
    
    /// Receives the vote the constituent wants to cast, and either accepts the vote or an error will be shown to the user
    app.post("vote", ":voteID") { req async throws -> Response in
        guard let (group, vote, constituent) = await voteGroupAndUserID(for: req) else{
            return req.redirect(to: .plaza)
        }
        
        // Chekcs that the vote is open
        guard await group.statusFor(await vote.id()) == .open else {
            switch vote {
            case .alternative(let v):
                return try await AltVotePageGenerator.closed(title: v.name).encodeResponse(for: req)
            case .yesno(let v):
                return try await YesNoVotePage.closed(title: v.name).encodeResponse(for: req)
            case .simplemajority(let v):
                return try await SimMajVotePage.closed(title: v.name).encodeResponse(for: req)
            }
        }
        

        switch vote {
        case .alternative(let v):
            return try await decodeAndStore(group: group, vote: v, constituent: constituent, req: req).encodeResponse(for: req)
        case .yesno(let v):
            return try await decodeAndStore(group: group, vote: v, constituent: constituent, req: req).encodeResponse(for: req)
        case .simplemajority(let v):
            return try await decodeAndStore(group: group, vote: v, constituent: constituent, req: req).encodeResponse(for: req)

        }

    }
    
    
    /// Checks that a vote can be accessed and renders the vote page
    /// - Returns: The relevant vote page; either in a "Redy to vote state" or an error state
    func checkAndShow<V: SupportedVoteType>(group: Group, constituent: Constituent, vote: V, errorString: String? = nil, persistentData: V.VotePageUI.PersistanceData? = nil) async -> UIManager{
        //Checks that the vote is open
        guard await group.statusFor(vote) == .open  else {
            return await V.VotePageUI.closed(title: await vote.name)
        }
        
        // Checks that the user hasn't voted yet
        guard !(await vote.hasConstituentVoted(constituent)) else{
            return await V.VotePageUI.hasVoted(title: await vote.name)
        }
        
        // Creates a vote page for the given vote
        return await V.VotePageUI.init(title: await vote.name, vote: vote, errorString: errorString, persistentData: persistentData)
    }
    
    /// Decodes data POSTed to /vote/[voteid], stores it if successfull, and renders the next page
    /// - Throws: VotingDataError
    /// - Returns: The view to be presented afterwards
    func decodeAndStore<V: SupportedVoteType>(group: Group, vote: V, constituent: Constituent, req: Request) async -> UIManager{
        var votingData: V.ReceivedData? = nil
        do {
            
            do {
                votingData = try req.content.decode(V.ReceivedData.self)
            } catch {
                // Workaround for an empty set of radio buttons giving error 422
                if (V.enumCase == .yesNo || V.enumCase == .simpleMajority), let e = error as? AbortError, e.status == .unprocessableEntity {
                    votingData = V.ReceivedData.blank()
                } else {
                    throw error
                }
            }
            let votingData = votingData!

            /// The vote as a SingleVote
            let singleVote = try await votingData.asSingleVote(for: vote, constituent: constituent)

            /// Saves the singleVote to the vote
            guard await vote.addVote(singleVote) else {
                throw VotingDataError.attemptedToVoteMultipleTimes
            }

            let voterID = singleVote.constituent.name ?? singleVote.constituent.identifier

            switch V.enumCase{
            case .alternative:
                return SuccessfullVoteUI(title: await vote.name, voterID: voterID, priorities: (singleVote as! SingleVote).rankings.map{$0.name})
            case .yesNo:
                let val = (singleVote as! yesNoVote.yesNoVoteType).values
                let prio: [String]
                if val.isEmpty{
                    prio = ["Voted blank"]
                } else {
                    // Finds the full list of options to recall them in order
                    prio = await vote.options.map { opt -> String in
                        if let option = val[opt]{
                            return opt.name + ": " + (option ? "Yes" : "No")
                        } else {
                            return opt.name + ": Blank"
                        }
                        
                    }
                }
                return SuccessfullVoteUI(title: await vote.name, voterID: voterID, priorities: prio)
            case .simpleMajority:
                let prio = (singleVote as! SimpleMajority.SimpleMajorityVote).preferredOption?.name ?? "Voted blank"

                return SuccessfullVoteUI(title: await vote.name, voterID: voterID, priorities: [prio])
            }

        } catch {
            return await checkAndShow(group: group, constituent: constituent, vote: vote, errorString: error.asString(), persistentData: votingData?.asCorrespondingPersistenseData())
        }
        
        
    }
    
    func voteGroupAndUserID(for req: Request) async -> (group: Group, vote: VoteTypes, constituent: Constituent)?{
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
