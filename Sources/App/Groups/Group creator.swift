import VoteKit
import Vapor
// Represents data received on a request to create a group
struct GroupCreatorData: Codable {
    var groupName: String
    private var file: String?
    private var adminpw: String
    private var allowsUnverifiedConstituents: String?
    private var generatePasswords: String?
}

extension GroupCreatorData {
    func getGroupName() throws -> String {
        let trim = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trim.isEmpty else {
            throw GroupCreationError.invalidGroupname
        }
        guard trim.count <= Config.maxNameLength else {
            throw GroupCreationError.groupNameTooLong
        }
        return trim
    }

    func getHashedPassword(for req: Request) throws -> String {
        return try hashPassword(pw: adminpw, groupName: try self.getGroupName(), for: req.application)
    }

    func getConstituents() throws -> Set<Constituent> {
        guard let file, !file.isEmpty else {
            if requiresPasswordGeneration {
                throw GroupCreationError.passwordGenerationRequiresFile
            } else {
                return []
            }
        }
        if file.count > 1_000_000 {
            throw GroupCreationError.nameTooLong
        }
        do {
            let dataList = try constituentDataListFromCSV(file: self.file!, maxNameLength: Int(Config.maxNameLength))

            guard dataList.compactMap(\.email).nonUniques().isEmpty else {
                throw GroupCreationError.emailAddedMultipleTimes
            }

            let constituents: [Constituent]
            if requiresPasswordGeneration {
                let names = dataList.map(\.name)
                guard !names.contains(nil), !names.contains(""), names.nonUniques().isEmpty else {
                    throw GroupCreationError.nonUniqueNamesForPasswordGeneration
                }

                constituents = try addPasswordToConstituents(data: dataList)
            } else {
                constituents = try dataList.getConstituents()

                // Checks that no one is using the name or identifier "admin"
                if (constituents.map(\.identifier) + constituents.compactMap(\.name).map {$0.lowercased()}).contains(where: {$0.contains("admin")}) {
                    throw DecodeConstituentError.invalidIdentifier
                }
                guard constituents.map(\.identifier).nonUniques().isEmpty else {
                    throw GroupCreationError.userAddedMultipleTimes
                }
            }

            return Set(constituents)

        } catch let er as DecodeConstituentError {
            throw GroupCreationError(from: er)
        }
    }

    /// Checks if the received data indicates that non verified constituents are allowed
    var allowsUnverified: Bool {
        self.allowsUnverifiedConstituents == "on"
    }

    /// Checks if the received data indicates that a password should be set for each user
    var requiresPasswordGeneration: Bool {
        self.generatePasswords == "on"
    }
}

indirect enum GroupCreationError: ErrorString {
    func errorString() -> String {
        switch self {
        case .userAddedMultipleTimes:
            return "User appears multiple times."
        case .invalidIdentifier:
            return "One or more invalid user identifiers were found."
        case .groupNameTooLong:
            return "The name of the group was too long (\(Config.maxNameLength))."
        case .invalidGroupname:
            return "The group name is invalid."
        case .invalidPassword:
            return "The password is either too short or too simple."
        case .invalidCSV:
            return "The supplied CSV file was invalid, use \",\" as separator between fields, use newlines between constituents."
        case .nameTooLong:
            return "One of the supplied constituents has a name/identifier/tag which surpasses the maximum name length (\(Config.maxNameLength)). "
        case .invalidTag:
            return "One of the supplied tags are invalid, either by having the prefix \"-\" or exceeding the length limit (\(Config.maxNameLength))."
        case .invalidEmail:
            return "One of the supplied emails are invalid."
        case .emailAddedMultipleTimes:
            return "An email was added multiple times."
        case .invalidHeader:
            return "The supplied CSV file has an invalid header row. Check that the header row contains the columns \"Name\" and \"Identifier\" separated by a comma \",\".\n\"Tag\" and \"Email\" are optional."
        case .nonUniqueNamesForPasswordGeneration:
            return "When generating unique access tokens every constituent should have a unique non empty name"
        case .passwordGenerationRequiresFile:
            return "To use password generation a file has to be uploaded first"
        case .lineError(error: let error, line: let line):
            return "[CSV line \(line)] " + error.errorString()
        }
    }

    case userAddedMultipleTimes, invalidIdentifier, groupNameTooLong, invalidGroupname, invalidPassword, invalidCSV, nameTooLong, invalidTag, invalidEmail, emailAddedMultipleTimes, invalidHeader, nonUniqueNamesForPasswordGeneration, passwordGenerationRequiresFile
    case lineError(error: Self, line: Int)
    func errorOnLine(_ line: Int) -> Self {
        if case .lineError = self {
            return self
        } else {
            return .lineError(error: self, line: line)
        }
    }
    init(from decodingError: DecodeConstituentError) {
        switch decodingError {
        case .invalidIdentifier:
            self = .invalidIdentifier
        case .nameTooLong:
            self = .nameTooLong
        case .invalidCSV:
            self = .invalidCSV
        case .invalidTag:
            self = .invalidTag
        case .invalidEmail:
            self = .invalidEmail
        case .invalidHeader:
            self = .invalidHeader
        case .lineError(error: let error, line: let line):
            self = Self(from: error).errorOnLine(line)
        }
    }
}
