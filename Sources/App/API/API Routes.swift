import Vapor
import VoteExchangeFormat
import Foundation
func APIRoutes(_ app: Application, routesGroup API: RoutesBuilder, groupsManager: GroupsManager){
    API.get(""){ _ throws -> Response in
        throw Abort(.badRequest)
    }
    
    /// userID: String
    /// joinPhrase: String
    API.post("join") { req async throws in
        try await joinGroup(req, groupsManager, forAPI: true)
    }
    
    API.get("getdata") { req async throws -> GroupData in
        guard
            let (group, const) = await groupsManager.groupAndVoterForAPI(req: req),
            let data = await group.getExchangeData(for: const.identifier)
        else {
            throw Abort(.unauthorized)
        }
        
        return data
    }
    
    /// Returns full information (metadata, options, validators) regarding a vote only if the client are allowed to vote at the moment
    API.get("getvote", ":voteid") { req async throws -> ExtendedVoteData in
      
        
        guard let (group, const) = await groupsManager.groupAndVoterForAPI(req: req) else {
            throw Abort(.unauthorized)
        }
        
        guard
            let voteIDStr = req.parameters.get("voteID"),
            let vote = await group.voteForID(voteIDStr)
        else {
            throw Abort(.notFound)
        }
        
        let voteData: ExtendedVoteData
        let voteStatus = await group.statusFor(await vote.id())
        switch vote {
        case .alternative(let v):
            guard !(await v.hasConstituentVoted(const)) && voteStatus == .open else {throw Abort(.unauthorized)}
            voteData = await ExtendedVoteData(v, constituentID: const.identifier, group: group)
        case .yesno(let v):
            guard !(await v.hasConstituentVoted(const)) && voteStatus == .open else {throw Abort(.unauthorized)}
            voteData = await ExtendedVoteData(v, constituentID: const.identifier, group: group)
        case .simplemajority(let v):
            guard !(await v.hasConstituentVoted(const)) && voteStatus == .open else {throw Abort(.unauthorized)}
            voteData = await ExtendedVoteData(v, constituentID: const.identifier, group: group)
        }
     
        return voteData
    }
}


