import VoteKit
import Vapor
//Represents data received on a request to create a group
struct GroupCreatorData: Codable{
	private let groupName: String
	private let file: String?
	private let allowsUnverifiedConstituents: String?
}

extension GroupCreatorData{
	func getGroupName() throws -> String{
		let trim = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trim.isEmpty else {
			throw GroupCreationError.invalidGroupname
		}
		guard trim.count <= Config.maxNameLength else {
			throw GroupCreationError.groupNameTooLong
		}
		return trim
	}
	
	func getEmails() throws -> [(value: String, tag: String?)] {
		guard let file = file else {
			return []
		}
		
		let list = file
			.split(separator: "\n")
			.map{ val -> [String] in
				String(val)
					.split(separator: ",", omittingEmptySubsequences: false)
					.map{$0.trimmingCharacters(in: .whitespacesAndNewlines)}
			}
		guard list.count >= 2 else{
			throw GroupCreationError.atLeastOneUserRequried
		}
		
		
		// Validates length
		for row in list {
			if let tooLong = row.first(where: {$0.count > Config.maxNameLength}) {
				throw GroupCreationError.nameTooLong(name: String(tooLong))
			}
		}
		
		// Validates header
		let header = list.first!
		guard header == ["email","tag"] else {
			throw GroupCreationError.invalidCSV(line: "Header")
		}
		
		// Validates body
		let body = list.dropFirst()
		
		if let tooShort = body.first(where: {$0.count != 2}) {
			throw GroupCreationError.invalidCSV(line: "\(tooShort)")
		}
		
		let userList: [(value: String, tag: String?)] = body.map{
			let tag: String? = $0[1].isEmpty ? nil : String($0[1])
			return (value: String($0[0]), tag: tag)
		}
		
		// Check uniqueness
		let nonUniques = userList.map(\.value).nonUniques()
		if !nonUniques.isEmpty {
			throw GroupCreationError.userAddedMultipleTimes(users: nonUniques.joined(separator: ", "))
		}
		
		
		// Verify emails
		if let firstError = userList
			.map(\.value)
			.map({ email -> (result: ValidatorResult, email: String) in
				(result: Validator.internationalEmail.validate(email), email: email)
			})
				.first(where: \.result.isFailure)
		{
			throw GroupCreationError.invalidEmail(email: firstError.email)
		}
		
		
		return userList
	}
	
	/// Checks if the received data indicates that non verified constituents are allowed
	func allowsUnverified() -> Bool{
		self.allowsUnverifiedConstituents.isOn
	}
}

enum GroupCreationError: ErrorString{
	func errorString() -> String {
		switch self {
			
		case .invalidIdentifier:
			return "One or more invalid user identifiers were found."
		case .groupNameTooLong:
			return "The name of the group was too long (\(Config.maxNameLength))."
		case .invalidGroupname:
			return "The group name is invalid."
			
			// CSV related
		case .userAddedMultipleTimes(let nonUniques):
			return "Some users appears multiple times.\n\(nonUniques)"
		case .invalidCSV(let line):
			return "The supplied CSV file was invalid, the separators needs to be \",\" and newlines. Check that the header row is \"Name,Identifier,Tag,Email\". Tag and Email are optional.\nError at \"\(line)\""
		case .nameTooLong(let name):
			return "\"\(name)\" surpasses the maximum name length (\(Config.maxNameLength)). "
		case .invalidTag:
			return "One of the supplied tags are invalid, either by having the prefix \"-\" or exceeding the length limit (\(Config.maxNameLength))."
		case .invalidEmail(let email):
			return "The email: \"\(email)\" is invalid."
		case .atLeastOneUserRequried:
			return "At least one constituent is required"
		case .adminMustBeIncluded:
			return "You must include yourself in the group"
		}
	}
	
	case invalidIdentifier, groupNameTooLong, invalidGroupname, invalidTag, atLeastOneUserRequried, adminMustBeIncluded
	case userAddedMultipleTimes(users: String)
	case nameTooLong(name: String)
	case invalidEmail(email: String)
	case invalidCSV(line: String)
}
