import VoteKit
struct VoteCreationReceivedData: Codable{
	let nameOfVote: String
	let options: String
	
	let customValidators: [String: String]
	let genericValidators: [String: String]
}

extension VoteCreationReceivedData{
	func getAllEnabledIDs() -> [String]{
        customValidators.filter(\.value.isOn).map(\.key)
		+
		genericValidators.filter(\.value.isOn).map(\.key)
	}
	
    func getGenValidators<V: VoteStub>() -> [GenericValidator<V>] {
		genericValidators
			.filter(\.value.isOn)
			.compactMap{ validator in GenericValidator.allValidators.first{$0.id == validator.key}}
	}
	
    func getCustomValidators<S: VoteStub, T: Validateable<S>>() -> [T] {
        customValidators
            .filter(\.value.isOn)
            .compactMap{ validator in T.allValidators.first { $0.id == validator.key }}
    }
    func getOptions<V: SupportedVoteType>(type: V.Type = V.self) throws(VoteCreationError) -> [VoteOption]{
		if self.options.contains(";"){
			throw VoteCreationError.invalidOptionName
		}
		
		let options = self.options
			.split(separator: ",")
			.map{String($0.trimmingCharacters(in: .whitespacesAndNewlines))}
			.filter{$0 != ""}
		
		guard options.nonUniques.isEmpty else{
			throw VoteCreationError.optionAddedMultipleTimes
		}
		
		if options.count < V.minimumRequiredOptions {
			// Use the title as an option in votes that allow single options
			if
				V.minimumRequiredOptions == 1,
				let title = try? self.getTitle(),
				!title.contains(","),
				!title.contains(";")
			{
				return [VoteOption(title)]
			}
			throw VoteCreationError.lessThanNOptions(V.minimumRequiredOptions)
		}
		
		// Checks that no option violates the maxNameLength constant
		guard options.allSatisfy({$0.count <= Config.maxNameLength}) else {
			throw VoteCreationError.invalidOptionName
		}
		
		return options.map(VoteOption.init)
	}
	
	func getTitle() throws(VoteCreationError) -> String{
		let title = nameOfVote.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !title.isEmpty, title.count <= Config.maxNameLength else {
			throw VoteCreationError.invalidTitle
		}
		return title
	}
}

enum VoteCreationError: ErrorString{
	case invalidTitle
	case optionAddedMultipleTimes
	case lessThanNOptions(Int)
	case invalidOptionName
	
	func errorString() -> String{
		
		switch self {
		case .invalidTitle:
			return "Invalid name detected for the vote"
		case .optionAddedMultipleTimes:
			return "An option has been added multiple times"
		case .lessThanNOptions(let n):
			return "A vote needs at least \(n) options"
		case .invalidOptionName:
			return "At least one of the options has an invalid name"
		}
	}
	
}
