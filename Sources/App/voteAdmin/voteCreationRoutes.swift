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
}

struct voteCreationReceivedData: Codable{
	var nameOfVote: String
	var options: String
	var usernames: String
	var validators: [String: String]
}


extension voteCreationReceivedData{
	func getValidators() -> [VoteValidator] {
		return validators.compactMap { validator in
			if validator.value == "on" {
				return voteUICreator.ValidatorData.allValidators[validator.key]
			} else {
				return nil
			}
		}
	}
	
	func getOptions() throws -> [VoteOption]{
		let options = self.options.split(separator: ",").compactMap{ opt -> String? in
			let str = String(opt.trimmingCharacters(in: .whitespacesAndNewlines))
			return str == "" ? nil : str
		}
		
		guard options.nonUniques.isEmpty else{
			throw voteCreationError.optionAddedMultipleTimes
		}
		return options.map{
			VoteOption($0)}
	}
	
	func getConstituents() throws -> Set<Constituent>{
		let individualVoters = self.usernames.split(whereSeparator: \.isNewline)
		
		let constituents = try individualVoters.compactMap{ voterString -> Constituent? in
			let s = voterString.split(separator:",")
			if s.count == 0 {
				return nil
			} else if s.count == 1 {
				let id = s.first!.trimmingCharacters(in: .whitespacesAndNewlines)
				guard !id.isEmpty else {
					throw voteCreationError.invalidUsername
				}
				return Constituent(identifier: id)
			} else if s.count == 2{
				let id = s.first!.trimmingCharacters(in: .whitespacesAndNewlines)
				
				let name = s.last!.trimmingCharacters(in: .whitespacesAndNewlines)
				guard !id.isEmpty, !name.isEmpty else {
					throw voteCreationError.invalidUsername
				}
				
				return Constituent(name: name, identifier: id)
				
			} else {
				throw voteCreationError.invalidUsername
			}
			
		}
		
		guard constituents.map(\.identifier).nonUniques.isEmpty else{
			throw voteCreationError.userAddedMultipleTimes
		}
		
		
		return Set(constituents)
		
	}
	
	
	func getTitle() throws -> String{
		let title = nameOfVote.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !title.isEmpty else {
			throw voteCreationError.invalidTitle
		}
		return title
	}
	
	
	enum voteCreationError: ErrorString{
		case invalidTitle
		case invalidUsername
		case userAddedMultipleTimes
		case optionAddedMultipleTimes
		case lessThanTwoOptions
		
		func errorString() -> String{
			
			switch self {
			case .invalidTitle:
				return "Invalid name detected for the vote"
			case .invalidUsername:
				return "Invalid username"
			case .userAddedMultipleTimes:
				return "A user has been added multiple times"
			case .optionAddedMultipleTimes:
				return "An option has been added multiple times"
			case .lessThanTwoOptions:
				return "A vote needs atleast 2 options"
			}
		}
		
	}
}

