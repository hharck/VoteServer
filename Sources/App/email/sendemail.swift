import Vapor

protocol EmailBackend{
//	var sendAdress: {get}
	func sendEmail(to: String, subject: String, body: String) async
}

extension EmailBackend{
	func sendAndVerifyEmail(to: String, subject: String, body: String) throws {
		if Validator.internationalEmail.validate(to).isFailure {
			throw EmailSendingError.invalidAddress(to)
		}
		Task{
			await self.sendEmail(to: to, subject: subject, body: body)
		}
		
		
	}

	
}

enum EmailSendingError: ErrorString{
	case invalidAddress(String)
	case tooLong
	
	func errorString() -> String {
		switch self{
		case .invalidAddress(let address):
			return "The email address is invalid: \"\(address)\""
		case .tooLong:
			return "Email too long"
		}
	}
}



struct EmailToLog: EmailBackend{
	private let logger = Logger(label: "Email sending")
	func sendEmail(to: String, subject: String, body: String) async{
		logger.info("""
   TO: \(to)
   FROM: VoteServer
   SUBJECT: \(subject.replacingOccurrences(of: "\n", with: " "))
   –––––––––––––––––––
   \(body)
   """)
	}
	
}
