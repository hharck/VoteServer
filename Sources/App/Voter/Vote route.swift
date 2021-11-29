import Foundation
import Vapor
import AltVoteKit

func votingRoutes(_ app: Application, groupsManager: GroupsManager) throws {
	app.get("vote", ":voteID") { req async throws -> Response in
		guard let (group, vote, userID) = await voteGroupAndUserID(for: req) else{
			return req.redirect(to: .plaza)
		}

		//Checks that the vote is open
		guard await group.statusFor(vote) == .open	else {
			return try await AltVotePageGenerator.closed(title: await vote.name).encodeResponse(for: req)
		}

		// Checks that the user hasn't voted yet
		guard !(await vote.hasConstituentVoted(userID)) else{
			return try await AltVotePageGenerator.hasVoted(title: await vote.name).encodeResponse(for: req)
		}

		return try await AltVotePageGenerator(title: await vote.name, vote: vote).encodeResponse(for: req)
	}
	
	
	app.post("vote", ":voteID") { req async throws -> Response in
		guard let (group, vote, constituent) = await voteGroupAndUserID(for: req) else{
			return req.redirect(to: .plaza)
		}

		//Checks that the vote is open
		guard await group.statusFor(vote) == .open	else {
			return try await AltVotePageGenerator.closed(title: await vote.name).encodeResponse(for: req)
		}

		// Checks that the user hasn't voted yet
		guard !(await vote.hasConstituentVoted(constituent)) else{
			return try await AltVotePageGenerator.hasVoted(title: await vote.name).encodeResponse(for: req)
		}

		var votingData: AltVotingData? = nil
		do {
			votingData = try req.content.decode(AltVotingData.self)
			let votingData = votingData!
			
			/// The vote as a SingleVote
			let singleVote = try await votingData.asSingleVote(for: vote, constituent: constituent)
		
			/// Saves the singleVote to the vote
			guard await vote.addVote(singleVote) else {
				throw VotingDataError.attemptedToVoteMultipleTimes
			}

			let voterID = singleVote.constituent.name ?? singleVote.constituent.identifier

			return try await SuccessfullVoteUI(title: await vote.name, voterID: voterID, priorities: singleVote.rankings.map{$0.name}).encodeResponse(for: req)

		} catch {
			let vpg = await AltVotePageGenerator(title: await vote.name, vote: vote, errorString: error.asString(), votingData)
			return try await vpg.encodeResponse(for: req)
		}


	}
	
	func voteGroupAndUserID(for req: Request) async -> (group: Group, vote: AltVote, user: Constituent)?{
		guard
			let voterSession = req.session.authenticated(VoterSession.self),
			let groupID = req.session.authenticated(GroupSession.self),
			let voteIDStr = req.parameters.get("voteID"),
			let group = await groupsManager.groupForGroupID(groupID),
			let constituent = await group.constituentsSessionID[voterSession],
			let vote = await group.voteForID(voteIDStr)
		else {
			return nil
		}

		return (group, vote, constituent)
	}
}
