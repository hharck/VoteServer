import Vapor
import AsyncHTTPClient
import AltVoteKit

func routes(_ app: Application) throws {
	let voteManager = VoteManager()

	app.get { req in
		req.redirect(to: "/create/")
	}

	try voteCreationRoutes(app, voteManager: voteManager)
	try votingRoutes(app, voteManager: voteManager)
	try ResultRoutes(app, voteManager: voteManager)

}
