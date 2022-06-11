extension String{
    var isOn: Bool{
        self == "on"
    }
}

extension Optional where Wrapped == String{
	var isOn: Bool{
		self == "on"
	}
}

import Vapor
extension Request.Authentication {
	
	public func require<A, E: Error>(_ type: A.Type = A.self, _ error: E) throws -> A
		where A: Authenticatable
	{
		guard let a = self.get(A.self) else {
			throw error
		}
		return a
	}
}
