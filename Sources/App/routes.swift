import Vapor
import AsyncHTTPClient
import AltVoteKit




func routes(_ app: Application) throws {
	app.get { req in
		req.redirect(to: "/create/")
	}
	

	
	app.get("v", ":voteAcces") { req -> String in
        return "Hello, world!"
    }
	try voteCreationRoutes(app)
}
