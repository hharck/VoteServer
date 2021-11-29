import AltVoteKit
struct VoteCreationReceivedData: Codable{
	var nameOfVote: String
	var options: String
	var validators: [String: String]
}


extension VoteCreationReceivedData{
	func getValidators() -> [VoteValidator] {
		return validators.compactMap { validator in
			if validator.value == "on" {
				return VoteUICreator.ValidatorData.allValidators[validator.key]
			} else {
				return nil
			}
		}
	}
	
	func getOptions() throws -> [VoteOption]{
		let options = self.options
			.split(separator: ",")
			.compactMap{ opt -> String? in
				let str = String(opt.trimmingCharacters(in: .whitespacesAndNewlines))
				return str == "" ? nil : str
			}
		
		
		guard options.nonUniques.isEmpty else{
			throw voteCreationError.optionAddedMultipleTimes
		}
		
		guard options.count >= 2 else {
			throw voteCreationError.lessThanTwoOptions
		}
		
		return options.map{
			VoteOption($0)}
	}
	
	func getTitle() throws -> String{
		let title = nameOfVote.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !title.isEmpty else {
			throw voteCreationError.invalidTitle
		}
		return title
	}
	
	
	enum voteCreationError: ErrorString{
		case invalidTitle
		case optionAddedMultipleTimes
		case lessThanTwoOptions
		
		func errorString() -> String{
			
			switch self {
			case .invalidTitle:
				return "Invalid name detected for the vote"
			case .optionAddedMultipleTimes:
				return "An option has been added multiple times"
			case .lessThanTwoOptions:
				return "A vote needs atleast 2 options"
			}
		}
		
	}
}

