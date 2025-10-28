//
//  addPasswordToConstituents.swift
//  
//
//  Created by Hans Harck Tønning on 26/02/2023.
//

import Vapor
import VoteKit

func addPasswordToConstituents(data: [HeaderValueDictionary]) throws -> [Constituent] {

    let passwords = try generatePasswords(numberOfPasswords: data.count)
    return try zip(data, passwords)
        .map { constituent, password in
            var constituent = constituent
            constituent[.identifier] = password
            return constituent
        }.getConstituents()
}


private func generatePasswords(numberOfPasswords: Int) throws(NumericError) -> Set<String> {
    let numberOfCharacters: UInt = 6

    let numberOfUniquePasswords = pow(Double(numberOfPossibleJoinPhraseChars), Double(numberOfCharacters) * 0.5)
    if numberOfUniquePasswords < Double(numberOfPasswords) * Double(numberOfPasswords) {
        // There is a high chance of collisions
        throw NumericError.tooLikely
    }

    var passwords = Set([Void](repeatElement(Void(), count: numberOfPasswords)).map{joinPhraseGenerator(chars: numberOfCharacters)})

    var attempts = 0
    // Checks if any collisions has happened and generates extra
    while passwords.count < numberOfPasswords {
        attempts += 1
        if attempts > 10 {
            throw NumericError.failed
        }
        let missing = numberOfPasswords - passwords.count
        passwords.formIntersection(Set([Void](repeatElement(Void(), count: missing)).map{joinPhraseGenerator(chars: numberOfCharacters)}))
    }

    assert(numberOfPasswords == passwords.count)
    return passwords
}

enum NumericError: String, ErrorString {
    case failed = "The server was extremely unlucky in its random number generation"
    case tooLikely = "There are too many constituents to generate an access token for all of them without collisions being likely"
}

