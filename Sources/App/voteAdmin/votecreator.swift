import AltVoteKit

struct voteCreator: Codable{
	let validators: [ValidatorData]
	let errorString: String
	
	struct ValidatorData: Codable{
		let name: String
		let id: String
		
		init(_ validator: VoteValidator){
			self.name = validator.name
			self.id = validator.id
		}
		
		static let allValidators: [String: VoteValidator] = {
			let allValidators: [VoteValidator] = [.oneVotePerUser, .everyoneHasVoted, .noForeignVotes, .preferenceForAllCandidates, .noBlankVotes]
			return allValidators.reduce(into: [String: VoteValidator]()) { partialResult, validator in
				partialResult[validator.id] = validator
			}}()
		
		static let allData: [ValidatorData] = {
			allValidators.map { _, val in
				Self.init(val)
			}}()
		
		func toValidator() -> VoteValidator?{
			Self.allValidators[id]
		}
	}
	
	init(validators: [ValidatorData] = ValidatorData.allData, errorString: String = "") {
		self.errorString = errorString
		self.validators = validators
	}
	init(validators: [VoteValidator], errorString: String = "") {
		self.errorString = errorString
		self.validators = validators.map{.init($0)}
	}
}
