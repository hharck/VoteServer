/*
 This protocol and extentension allows any error to be converted into a string error.asString()
 ErrorString allows for a costum conversion of supported types
 */

protocol ErrorString: Error {
	func errorString() -> String
}

extension ErrorString where Self: RawRepresentable, Self.RawValue == String {
	func errorString() -> String {
		self.rawValue
	}
}

extension Error {
	func asString() -> String{
		if let er = (self as? ErrorString) {
			return er.errorString()
		} else {
			if let str = self as? LosslessStringConvertible{
				return str.description
			} else {
				return "Unknown error: \(self.localizedDescription)"
			}
		}
	}
}
