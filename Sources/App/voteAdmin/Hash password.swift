import Vapor

func hashPassword(pw: String, groupName: String, for app: Application) throws -> String{
    let trimmedPW = pw.trimmingCharacters(in: .whitespacesAndNewlines)
    
    guard trimmedPW.count >= 7, groupName.count < 3 || (!trimmedPW.contains(groupName) && !groupName.contains(trimmedPW)) else {
        throw UserCreationError.invalidPassword
    }
    
    return try app.password.hash(trimmedPW)
}

enum UserCreationError: Error{
	case invalidPassword
}
