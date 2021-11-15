import Foundation
import Vapor
import AltVoteKit

func votingRoutes(_ app: Application, voteManager: VoteManager) throws {
	
	app.get("v", ":voteaccess") { req async throws -> View in
		let proposedJF = req.parameters.get("voteaccess")!

		
		guard let vote = await voteManager.voteFor(joinPhrase: proposedJF) else {
			throw "Invalid url"
		}
		
		//Checks that the vote is open
		guard await voteManager.statusFor(vote) == true else {
			let vpg = VotePageGenerator(title: await vote.name)
			return try await req.view.render("vote", vpg)
		}
		
		
		
		let options = await vote.options
		
		let vpg = VotePageGenerator(title: await vote.name, options: options)
		return try await req.view.render("vote", vpg)
	}
	
	
	app.post("v", ":voteaccess") { req async throws -> View in
		let proposedJF = req.parameters.get("voteaccess")!
		
		guard let vote = await voteManager.voteFor(joinPhrase: proposedJF) else {
			throw "Invalid url"
		}
		
		//Checks that the vote is open
		guard await voteManager.statusFor(vote) == true else {
			let vpg = VotePageGenerator(title: await vote.name)
			return try await req.view.render("vote", vpg)
		}
		
		
		
		
		do {
			let votingData = try req.content.decode(VotingData.self)
			
			// Checks that the user hasn't vpted befpre
		
			
			let singleVote = try await votingData.asSingleVote(for: vote)
		
			
			guard await vote.addVotes(singleVote) else {
				throw VotingDataError.attemptedToVoteMultipleTimes
			}
			
			return try await req.view.render("success", DidVote(title: await vote.name, voterID: singleVote.userID, priorities: singleVote.rankings.map{$0.name}))

		} catch {
			let options = await vote.options
			
			let vpg = VotePageGenerator(title: await vote.name, options: options, errorString: error.asString())
			return try await req.view.render("vote", vpg)
		}
		
		
	}
}
