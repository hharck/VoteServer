import VoteKit

struct GroupSettings: Codable, Sendable{
    internal init(allowsUnverifiedConstituents: Bool, constituentsCanSelfResetVotes: Bool = false, csvConfiguration: CSVConfiguration = .defaultConfiguration()) {
        self.allowsUnverifiedConstituents = allowsUnverifiedConstituents
        self.constituentsCanSelfResetVotes = constituentsCanSelfResetVotes
        self.csvConfiguration = csvConfiguration
        
        let allCSVConfigurations: [CSVConfiguration] = [.defaultConfiguration(),.SMKid()]
        self.csvKeys = allCSVConfigurations.reduce(into: [String: CSVConfiguration](), { $0[$1.name] = $1})
    }
    
    /// If this group allows unverified constituents to join
    var allowsUnverifiedConstituents: Bool
    
    /// Whether constituens should be able to reset their own votes
    var constituentsCanSelfResetVotes: Bool = false
    
    var csvConfiguration: CSVConfiguration = .defaultConfiguration()
    
    let csvKeys: [String: CSVConfiguration]
}
