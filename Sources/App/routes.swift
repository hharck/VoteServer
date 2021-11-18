import Vapor
import AsyncHTTPClient
import AltVoteKit

func routes(_ app: Application) throws {
	let voteManager = VoteManager()

	app.get { req in
		req.redirect(to: "/create/")
	}
	
	app.get("version"){req async in
		return "Server version: 0.1.0\nAltVoteKit version \(AltVoteKitVersion)"
	}

	try voteCreationRoutes(app, voteManager: voteManager)
	try votingRoutes(app, voteManager: voteManager)
	try ResultRoutes(app, voteManager: voteManager)

}
