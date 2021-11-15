//
//  File.swift
//  
//
//  Created by Hans Harck Tønning on 12/11/2021.
//

import AltVoteKit
import Foundation
typealias JoinPhrase = String

actor VoteManager{
	private var votesBySession = [SessionID: Vote]()
	private var votesByPhrase = [JoinPhrase: Vote]()

	/// The open/closedness status of a vote. true <=> open
	private var statusForVote = [Vote: Bool]()
	
	//MARK: Getters
	func voteFor(session: SessionID) async -> Vote?{
		votesBySession[session]
	}
	
	func voteFor(joinPhrase: JoinPhrase) async -> Vote?{
		votesByPhrase[joinPhrase]
	}
	
	/// Get the status of a vote for a a session id
	func statusFor(session: SessionID) async -> Bool?{
		guard let vote = await voteFor(session: session) else {
			return nil
		}
		return statusForVote[vote]
	}
	
	/// Get the status of a vote
	func statusFor(_ vote: Vote) async -> Bool?{
		statusForVote[vote]
	}
	
	func setStatusFor(_ vote: Vote, to value: Bool) async{
		statusForVote[vote] = value
	}
	
	//MARK: Add new votes
	func addVote(vote: Vote) async{
		await addVote(vote: vote, joinPhrase: createJoinPhrase())
	}
	
	func addVote(vote: Vote, joinPhrase: JoinPhrase) async{
		votesByPhrase[joinPhrase] = vote
		await vote.setData(key: "joinphrase", value: joinPhrase)
		
		statusForVote[vote] = false
		votesBySession[await vote.id] = vote
	}

	func getJoinPhraseFor(vote: Vote) async -> JoinPhrase?{
		await vote.getData(key: "joinphrase")
	}
	
	
	//MARK: Support for creating joinphrases
	public var reservedPhrases = Set<String>()
	
	
	
	func createJoinPhrase() async -> JoinPhrase{
		let phrase = gencharphrase()
		
		// If a phrase can be inserted without overwriting another element then it must be unique
		if reservedPhrases.insert(phrase).inserted {
			return phrase
		} else {
			//Otherwise we'll try again
			return await createJoinPhrase()
		}
	}
}





fileprivate func gencharphrase(chars: Int = 8) -> String{
	let possibleChars: Set<Character> = {
		var set = Set<Character>()
		for i in 0...9{
			set.insert(Character(i.description))
		}
		
		//Based on https://stackoverflow.com/a/63760652/5257653
		let aScalars = "a".unicodeScalars
		let aCode = Int(aScalars[aScalars.startIndex].value)
		
		for i in 0..<26{
			set.insert(Character(Unicode.Scalar(aCode + i) ?? aScalars[aScalars.startIndex]))
		}
		
		return set
	}()
	
	
	return String((1...chars).map{ _ in possibleChars.randomElement()!})
	
	
}
