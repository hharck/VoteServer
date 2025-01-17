import VoteKit
import AltVoteKit
import Vapor

/// Decodes and stores data POSTed to /vote/[voteid] OR the API
/// - Throws: VotingDataError
/// - Returns: Either a view to be presented be non API clients or the result as a String for API clients
@Sendable func decodeAndStore<V: SupportedVoteType>(group: Group, vote: V, constituent: Constituent, req: Request) async throws(Abort) -> ((data: V.ReceivedData?, error: Error)?, [String]?){
    var votingData: V.ReceivedData
    do {
        votingData = try req.content.decode(V.ReceivedData.self)
    } catch {
        // Workaround for an empty set of radio buttons leading to error 422
        if (V.enumCase == .yesNo || V.enumCase == .simpleMajority), let e = error as? AbortError, e.status == .unprocessableEntity {
            votingData = V.ReceivedData.blank()
        } else {
            return ((nil, error), nil)
        }
    }
    
    /// The vote as a VoteStub
    let voteStub: V.VoteType
    do {
        voteStub = try await votingData.asSingleVote(for: vote, constituent: constituent)
    } catch {
        return ((votingData, error), nil)
    }
    
    /// Saves the singleVote to the vote
    guard await vote.addVote(voteStub) else {
        return ((votingData, VotingDataError.attemptedToVoteMultipleTimes), nil)
    }
    
    // Returns a list of priorities to show the user as confirmation for a cast vote
    let prio: [String] = switch V.enumCase{
    case .alternative:
        if let tmp = (voteStub as? SingleVote)?.rankings.map(\.name) {
            if tmp.isEmpty{
                ["Voted blank"]
            } else{
                tmp
            }
        } else {
            throw Abort(.internalServerError)
        }
    case .yesNo:
        if let val = (voteStub as? YesNoVote.YesNoVoteType)?.values {
            if val.isEmpty {
                ["Voted blank"]
            } else {
                // Fetches the full list of options to recall them in order
                await vote.options.map{ opt -> String in
                    let suffix: String
                    if let option = val[opt]{
                        suffix = option ? "Yes" : "No"
                    } else {
                        suffix = "Blank"
                    }
                    return opt.name + ": " + suffix
                }
            }
        } else {
            throw Abort(.internalServerError)
        }
    case .simpleMajority:
        if let vote = voteStub as? SimpleMajority.SimpleMajorityVote {
            [vote.preferredOption?.name ?? "Voted blank"]
        } else {
            throw Abort(.internalServerError)
        }
    }
    return (nil, prio)
}
