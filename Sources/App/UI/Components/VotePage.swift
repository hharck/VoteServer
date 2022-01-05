/// The basis for a page in which a user can cast a vote
protocol VotePage: UIManager{
    associatedtype VoteType: SupportedVoteType
    associatedtype PersistanceData: Codable

    var canVoteBlank: Bool {get}
    var hideUI: Bool {get set}
    
    static func closed(title: String) async -> Self
    static func hasVoted(title: String) async -> Self
    
    /// The default initialiser; title is mostly just vote.name, but due to the possibility of a nil vote, it has to be supplied manually
    init(title: String, vote: VoteType?, errorString: String?, persistentData: PersistanceData?) async
}

extension VotePage{
    /// Adds a button for going back to the plaza
    var buttons: [UIButton] {[.backToPlaza]}
    
    static func closed(title: String) async -> Self{
        var closedVPG = await self.init(title: title, vote: nil, errorString: "Vote is currently closed", persistentData: nil)
        closedVPG.hideUI = true
        return closedVPG
    }
    
    static func hasVoted(title: String) async -> Self{
        var hasVotedVPG = await self.init(title: title, vote: nil, errorString: "You have already voted once, ask the admin to reset your vote", persistentData: nil)
        hasVotedVPG.hideUI = true
        return hasVotedVPG
    }
}
