@testable import App
import XCTVapor
//import Vapor

final class AppTests: XCTestCase {
    override func setUp() {
        var location = #file
        let expectedSuffix = "Tests/" + #fileID
     	precondition(location.hasSuffix(expectedSuffix))
        
        location.removeLast(expectedSuffix.count)
        
        FileManager.default.changeCurrentDirectoryPath(location)
    }
    
    func testDefaultStuff() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)

		// Test default redirect
		try app.test(.GET, "", afterResponse: { res in
			XCTAssertEqual(res.status, .seeOther)
		})
		
		// Tests 404
		try app.test(.GET, "fdasfjgkgjskldfjgkædsjfgækasd", afterResponse: { res in
			XCTAssertEqual(res.status, .notFound)
		})
		
		// Tests that /create loads
		try app.test(.GET, "create", afterResponse: { res in
			XCTAssertEqual(res.status, .ok)
			XCTAssertGreaterThan(res.body.string.count, 100)
		})
    }
	
	// Runs a signup flow
	func testCreateGroup() throws {
		let app = Application(.testing)
		defer { app.shutdown() }
		try configure(app)

		var header = HTTPHeaders()
		
		// Goes to /admin without access and gets redirected
		try app.test(.GET, "admin", headers: header, afterResponse: { res in
			XCTAssertEqual(res.status, .seeOther)
			XCTAssert(res.body.string.isEmpty)
		})

		// Goes to /createvote and gets redirected
		try app.test(.GET, "createvote/yesno", headers: header, afterResponse: { res in
			XCTAssertEqual(res.status, .seeOther)
		})
		try app.test(.POST, "createvote/yesno", headers: header, afterResponse: { res in
			XCTAssertEqual(res.status, .seeOther)
		})
		
		// Creates a group
		try app.test(.POST, "create", beforeRequest: { req in
			let dict = [
				"groupName": "Test group",
				"adminpw": "123456789",
				"usernames": "Person a, Person b",
				"allowsUnverifiedConstituents": "off"
			]
			
			try req.content.encode(dict)
		}) {res in
		 
			header.cookie = res.headers.setCookie
			XCTAssertEqual(res.status, .seeOther)
		}
		
		// Tries to access /admin again, now with success
		try app.test(.GET, "admin", headers: header, afterResponse: { res in
			XCTAssertEqual(res.status, .ok)
			XCTAssertGreaterThan(res.body.string.count, 100)
		})
		
		// Tries to access /createvote again, now with success
		try app.test(.GET, "createvote/yesno", headers: header, afterResponse: { res in
			XCTAssertEqual(res.status, .ok)
			XCTAssertGreaterThan(res.body.string.count, 100)
		})
	}
}
