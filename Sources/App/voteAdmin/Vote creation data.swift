import AltVoteKit
struct voteCreationReceivedData: Codable{
	var nameOfVote: String
	var options: String
	var usernames: String
	var validators: [String: String]
}


extension voteCreationReceivedData{
	func getValidators() -> [VoteValidator] {
		return validators.compactMap { validator in
			if validator.value == "on" {
				return voteUICreator.ValidatorData.allValidators[validator.key]
			} else {
				return nil
			}
		}
	}
	
	func getOptions() throws -> [VoteOption]{
		let options = self.options.split(separator: ",").compactMap{ opt -> String? in
			let str = String(opt.trimmingCharacters(in: .whitespacesAndNewlines))
			return str == "" ? nil : str
		}
		
		guard options.nonUniques.isEmpty else{
			throw voteCreationError.optionAddedMultipleTimes
		}
		return options.map{
			VoteOption($0)}
	}
	
	func getConstituents() throws -> Set<Constituent>{
		let individualVoters = self.usernames.split(whereSeparator: \.isNewline)
		
		let constituents = try individualVoters.compactMap{ voterString -> Constituent? in
			let s = voterString.split(separator:",")
			if s.count == 0 {
				return nil
			} else if s.count == 1 {
				let id = s.first!.trimmingCharacters(in: .whitespacesAndNewlines)
				guard !id.isEmpty else {
					throw voteCreationError.invalidUsername
				}
				return Constituent(identifier: id)
			} else if s.count == 2{
				let id = s.first!.trimmingCharacters(in: .whitespacesAndNewlines)
				
				let name = s.last!.trimmingCharacters(in: .whitespacesAndNewlines)
				guard !id.isEmpty, !name.isEmpty else {
					throw voteCreationError.invalidUsername
				}
				
				return Constituent(name: name, identifier: id)
				
			} else {
				throw voteCreationError.invalidUsername
			}
			
		}
		
		guard constituents.map(\.identifier).nonUniques.isEmpty else{
			throw voteCreationError.userAddedMultipleTimes
		}
		
		
		return Set(constituents)
		
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
		case invalidUsername
		case userAddedMultipleTimes
		case optionAddedMultipleTimes
		case lessThanTwoOptions
		
		func errorString() -> String{
			
			switch self {
			case .invalidTitle:
				return "Invalid name detected for the vote"
			case .invalidUsername:
				return "Invalid username"
			case .userAddedMultipleTimes:
				return "A user has been added multiple times"
			case .optionAddedMultipleTimes:
				return "An option has been added multiple times"
			case .lessThanTwoOptions:
				return "A vote needs atleast 2 options"
			}
		}
		
	}
}

