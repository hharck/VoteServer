import AltVoteKit

struct VoteUICreator: UIManager{
	var title: String = "Create vote"
	var errorString: String?
	static var template: String = "createvote"
	
	let validators: [ValidatorData]
	let nameOfVote: String
	let options: String
	
	struct ValidatorData: Codable{
		var name: String
		var id: String
		var isEnabled: Bool
		
		init(_ validator: VoteValidator, isEnabled: Bool = false){
			self.name = validator.name
			self.id = validator.id
			self.isEnabled = isEnabled
		}
		
		static let allValidators: [String: VoteValidator] = {
			let allValidators: [VoteValidator] = [.everyoneHasVoted, .preferenceForAllCandidates, .noBlankVotes]
			return allValidators.reduce(into: [String: VoteValidator]()) { partialResult, validator in
				partialResult[validator.id] = validator
			}
			
		}()
		
		static let allData: [ValidatorData] = {
			allValidators.map { _, val in
				Self.init(val)
			}
			.sorted(by: {$0.name < $1.name})
		}()
		
		func toValidator() -> VoteValidator?{
			Self.allValidators[id]
		}
	}
	
	init(validators: [ValidatorData] = ValidatorData.allData, errorString: String? = nil, _ persistentData: VoteCreationReceivedData? = nil) {
		nameOfVote = persistentData?.nameOfVote ?? ""
		options = persistentData?.options.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
		
		self.errorString = errorString
		
		// Sets the validator as enabled if they appear in persistentData
		if let enabledValidatorIDs = persistentData?.getValidators().map(\.id), !enabledValidatorIDs.isEmpty{
			self.validators = validators.map{val in
				var val = val
				val.isEnabled = enabledValidatorIDs.contains(val.id)
				return val
			}
		} else {
			self.validators = validators
		}
	}
	
	init(validators: [VoteValidator], errorString: String? = nil, _ persistentData: VoteCreationReceivedData? = nil) {
		self.init(validators: validators.map{.init($0)}, errorString: errorString, persistentData)
	}
}
