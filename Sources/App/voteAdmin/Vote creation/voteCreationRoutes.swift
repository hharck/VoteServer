import Vapor
import Fluent
import VoteKit
import AltVoteKit
import VoteExchangeFormat

func voteCreationRoutes(_ path: RoutesBuilder, groupsManager: GroupsManager) {
    /// Shows admins a page which'' let them create the kind of vote supplied in the "type" parameter
    path.get(":type", use: createVote)
	path.post(":type", use: createVote)
	func createVote(req: Request) async throws -> Response{
		#warning("Check if user is allowed to create a vote")
		let dbGroup = try req.auth.require(DBGroup.self, Redirect(.create))
		
		guard let parameter = req.parameters.get("type"), let type = VoteMetadata.Kind(rawValue: parameter) else {
			throw Redirect(.admin)
		}
		
		let group = await groupsManager.groupForGroup(dbGroup)
		
		if req.method == .POST{
			switch type {
			case .AlternativeVote:
				return try await treat(req: req, AlternativeVote.self, group: group, dbGroup: dbGroup)
			case .YNVote:
				return try await treat(req: req, yesNoVote.self, group: group, dbGroup: dbGroup)
			case .SimMajVote:
				return try await treat(req: req, SimpleMajority.self, group: group, dbGroup: dbGroup)
			}
		} else {
			switch type {
			case .AlternativeVote:
				return try await showUI(for: req, AlternativeVote.self)
			case .YNVote:
				return try await showUI(for: req, yesNoVote.self)
			case .SimMajVote:
				return try await showUI(for: req, SimpleMajority.self)
			}
		}
	}
}

/// Attempts to create a vote for a given request
fileprivate func treat<V: VoteProtocol>(req: Request, _ type: V.Type, group: Group, dbGroup: DBGroup) async throws -> Response{
	var voteHTTPData: VoteCreationReceivedData<V>? = nil

    do {

        voteHTTPData = try req.content.decode(VoteCreationReceivedData<V>.self)

        // Since it voteHTTPData was just set it'll in this scope be treated as not being an optional
		let voteHTTPData = voteHTTPData!
		
		
		let c = try await dbGroup
			.$constituents
			.query(on: req.db)
			.filter(\.$isBanned == false)
			.join(DBUser.self, on: \DBUser.$id == \GroupConstLinker.$constituent.$id)
			.all()
		
//		c.first!.jo
//		print(c.first?.joined(<#T##model: Schema.Protocol##Schema.Protocol#>))
//		print(c.first?.constituent.name)
		let constituents = Set(try c.asConstituents())
			
//			try await dbGroup.$constituents
//				.query(on: req.db)
//				.filter(\.$isCurrentlyIn == true)
//				.join(GroupConstLinker.self, on: \GroupConstLinker.$constituent.$id == \)
//				.all()
//
		
		// Validates the data and generates a Vote object
		let title = try voteHTTPData.getTitle()
        let partValidators = voteHTTPData.getPartValidators()
        let genValidators = voteHTTPData.getGenValidators()
        let options = try voteHTTPData.getOptions()

        // Initialises the vote for the given type
        switch type.kind {
        case .AlternativeVote:
            let tieBreakers: [TieBreaker] = [.dropAll, .removeRandom, .keepRandom]
            
            let vote = AlternativeVote(name: title, options: options, constituents: constituents, tieBreakingRules: tieBreakers, genericValidators: genValidators as! [GenericValidator<AlternativeVote.voteType>], particularValidators: partValidators as! [AlternativeVote.particularValidator])
            await group.addVoteToGroup(vote: vote)
        case .YNVote:
            let vote = yesNoVote(name: title, options: options, constituents: constituents, genericValidators: genValidators as! [GenericValidator<yesNoVote.yesNoVoteType>], particularValidators: partValidators as! [yesNoVote.particularValidator])
            await group.addVoteToGroup(vote: vote)
        case .SimMajVote:
            let vote = SimpleMajority(name: title, options: options, constituents: constituents, genericValidators: genValidators as! [GenericValidator<SimpleMajority.SimpleMajorityVote>], particularValidators: partValidators as! [SimpleMajority.particularValidator])
            await group.addVoteToGroup(vote: vote)
        }

        return req.redirect(to: .admin)

    } catch {
        return try await showUI(for: req, errorString: error.asString(), persistentData: voteHTTPData)
    }
}



fileprivate func showUI<V: VoteProtocol>(for req: Request, _ type: V.Type = V.self, errorString: String? = nil, persistentData: VoteCreationReceivedData<V>? = nil) async throws -> Response{
    
    //Finds available validators
    let gen = GenericValidator<V.voteType>
        .allValidators
        .map{ genVal in
            ValidatorData<V>(genericValidator: genVal, isEnabled: false)
        }
    let part = V.particularValidator
        .allValidators
        .map{ partVal in
            ValidatorData<V>(particularValidator: partVal, isEnabled: false)
        }
    
    return try await VoteCreatorUI(errorString: errorString, validatorsGeneric: gen, validatorsParticular: part, persistentData).encodeResponse(for: req)
}



struct ValidatorData<V: VoteProtocol>: Codable{
    var id: String
    var name: String
    var isEnabled: Bool
    var stack: ValidatorStacks
    
    init(particularValidator: V.particularValidator, isEnabled: Bool = false){
        self.name = particularValidator.name
        self.id = particularValidator.id
        self.isEnabled = isEnabled
        self.stack = .particularValidators
    }
    
    init(genericValidator: GenericValidator<V.voteType>, isEnabled: Bool = false){
        self.name = genericValidator.name
        self.id = genericValidator.id
        self.isEnabled = isEnabled
        self.stack = .genericValidators
    }
    
    
    enum ValidatorStacks: String, Codable{
        case genericValidators
        case particularValidators
    }
}
