protocol ErrorString: Error {
	func errorString() -> String
}

extension Error {
	func asString() -> String{
		if let er = (self as? ErrorString) {
			return er.errorString()
		} else {
			if let str = self as? LosslessStringConvertible{
				return str.description
			} else {
				return "Unknown error"
			}
		}
	}
}
