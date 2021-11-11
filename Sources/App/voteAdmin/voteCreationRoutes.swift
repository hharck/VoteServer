//
//  File.swift
//  
//
//  Created by Hans Harck Tønning on 10/11/2021.
//

import Vapor
import AltVoteKit
func voteCreationRoutes(_ app: Application) throws {
	
	app.get("create") { req in
		
		return req.view.render("createvote", voteCreator())
	}
	
	app.post("create") { req -> EventLoopFuture<View> in
	
		
		
		do {
			let voteHTTPData = try req.content.decode(voteCreationReceivedData.self)
			
			let tieBreakers: [TieBreaker] = [.dropAll, .removeRandom, .keepRandom]
			
			
			
			let vote = Vote(options: try voteHTTPData.getOptions(), votes: [], validators: try voteHTTPData.getValidators(), eligibleVoters: try voteHTTPData.getUserIDs(), tieBreakingRules: tieBreakers)
			print(voteHTTPData)
			print(voteHTTPData.getValidators().map(\.name))
			
			
			
			fatalError()
		} catch {
			let er = (error as? voteCreationReceivedData.voteCreationError) ?? .unknownError
			
			return req.view.render("createvote", voteCreator(errorString: er.errorString()))
		}

	}
	
}


struct voteCreationReceivedData: Codable{
	var nameOfVote: String
	var options: String
	var usernames: String
	var validators: [String: String]
}

extension Array where Element : Equatable {
	var nonUniques: [Self.Element] {
		var allUnique: [Self.Element] = []
		
		
		return self.compactMap{ element -> Self.Element? in
			if allUnique.contains(element){
				return element
			} else {
				allUnique.append(element)
				return nil
			}
		}
	}
	
	
}

extension voteCreationReceivedData{
	func getValidators() -> [VoteValidator] {
		return validators.compactMap { validator in
			if validator.value == "on" {
				return voteCreator.ValidatorData.allValidators[validator.key]
			} else {
				return nil
			}
		}
	}
	
	func getOptions() throws -> [AltVoteKit.Option]{
		let options = self.options.split(separator: ",").compactMap{ opt -> String? in
			let str = String(opt.trimmingCharacters(in: .whitespacesAndNewlines))
			return str == "" ? nil : str
		}
		
		guard options.nonUniques.isEmpty else{
			throw voteCreationError.optionAddedMultipleTimes
		}
		return options.map{
			Option($0)}
		}
	
	func getUserIDs() throws -> Set<UserID>{
		let usernames = self.usernames.split(separator: ",").map{
			String($0.trimmingCharacters(in: .whitespacesAndNewlines))
		}
		
		guard usernames.nonUniques.isEmpty else{
			throw voteCreationError.userAddedMultipleTimes
		}
		
		if usernames.contains(""){
			throw voteCreationError.invalidUsername
		} else {
			return Set(usernames)
		}
	}
	
	enum voteCreationError: Error{
		case invalidName
		case invalidUsername
		case userAddedMultipleTimes
		case optionAddedMultipleTimes
		case lessThanTwoOptions
		case unknownError
		
		func errorString() -> String{
			
			switch self {
			case .invalidName:
				return "Invalid name detected for the vote"
			case .invalidUsername:
				return "Invalid username"
			case .userAddedMultipleTimes:
				return "A user has been added multiple times"
			case .optionAddedMultipleTimes:
				return "An option has been added multiple times"
			case .lessThanTwoOptions:
				return "A vote needs atleast 2 options"
			case .unknownError:
				return "An unknown error occured, check your input"
			}
		}
		
	}
}

