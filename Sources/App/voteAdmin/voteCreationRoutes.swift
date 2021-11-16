//
//  File.swift
//  
//
//  Created by Hans Harck Tønning on 10/11/2021.
//

import Vapor
import AltVoteKit
func voteCreationRoutes(_ app: Application, voteManager: VoteManager) throws {
	
	app.get("create") { req in
		return req.view.render("createvote", voteUICreator())
	}
	
	app.post("create") { req async throws -> Response in
		do {
			let voteHTTPData = try req.content.decode(voteCreationReceivedData.self)
			
			let tieBreakers: [TieBreaker] = [.dropAll, .removeRandom, .keepRandom]
			
			// Creates an ID for the session
			let session = Session()
			
			// Validates the data and generates a Vote object
			let vote = Vote(id: session.sessionID, name: try voteHTTPData.getTitle(), options: try voteHTTPData.getOptions(), votes: [], validators: voteHTTPData.getValidators(), eligibleVoters: try voteHTTPData.getConstituents(), tieBreakingRules: tieBreakers)
			
			//Stores the vote
			await voteManager.addVote(vote: vote)
			
			//Creates a session
			req.session.authenticate(session)
			
			print(voteHTTPData)
			print(voteHTTPData.getValidators().map(\.name))
			
			return req.redirect(to: "/voteadmin/")
			
		} catch {
			
			return try await req.view.render("createvote", voteUICreator(errorString: error.asString())).encodeResponse(for: req)
		}
		
	}
	
	app.get("voteadmin") { req async throws -> Response in
		guard
			let sessionID = req.session.authenticated(Session.self),
			let pageController = await VoteAdminUIController(votemanager: voteManager, sessionID: sessionID)
		else {
			return req.redirect(to: "/create/")
		}
		
		return try await req.view.render("voteadmin", pageController).encodeResponse(for: req)
	}
	
	app.post("voteadmin") { req async throws -> Response in

		
		guard let sessionID = req.session.authenticated(Session.self) else {
			return req.redirect(to: "/create/")
		}
		
		
		guard let status = (try req.content.decode([String:statusChange].self))["statusChange"] else {
			let pageController = await VoteAdminUIController(votemanager: voteManager, sessionID: sessionID)
			return try await req.view.render("voteadmin", pageController).encodeResponse(for: req)
		}
		
		guard let vote = await voteManager.voteFor(session: sessionID) else {
			throw "An error occured"
		}
		
		

		await voteManager.setStatusFor(vote, to: status == .open)

		if status == .getResults{
			return req.redirect(to: "/results/")
		} else {
			let pageController = await VoteAdminUIController(votemanager: voteManager, sessionID: sessionID)
			return try await req.view.render("voteadmin", pageController).encodeResponse(for: req)
		}
	}
	
	
	app.post("reset", ":uuid") { req async -> Response in
		guard
			let sessionID = req.session.authenticated(Session.self),
			let vote = await voteManager.voteFor(session: sessionID),
			let idStr = req.parameters.get("uuid"),
			let id = UUID(idStr)
		else {
			return req.redirect(to: "/voteadmin/")
		}
	
		await vote.resetVoteForUser(id)
		return req.redirect(to: "/voteadmin/")
	}
}

