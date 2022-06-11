import VoteKit
import Vapor
import Logging
import FluentKit

typealias JoinPhrase = String

/// Represents a collection of groups
actor GroupsManager{
	/// Groups represented by their internal id
	private var groupsByUUID = [UUID: Group]()
	private var reservedPhrases = Set<JoinPhrase>()
	private let logger = Logger(label: "Groups")
}


//MARK: Store last access
extension GroupsManager{
	#warning("Skal kaldes fra ALLE relevante steder, såsom alle steder hvor DBGroup hentes fra databasen, hvilket kun bør være ét sted, middlewaren")
	private func updateAccessTimeFor(_ group: DBGroup, for req: Request) async throws {
		group.lastAccess = Date()
		try await group.save(on: req.db)
	}
//
//	private func updateAccessTimeFor(_ group: Group) async{
//		await updateAccessTimeFor(group.id)
//	}
//
//    func getLastAccess(for group: DBGroup) -> String?{
//		group.lastAccess?.description
//    }
}

//MARK: Get and create groups
extension GroupsManager{
	func groupForGroup(_ dbgroup: DBGroup) -> Group{
		if let group = groupsByUUID[dbgroup.id!]{
			return group
		} else {
			let group = Group(dbgroup)
			groupsByUUID[dbgroup.id!] = group
			return group
		}
	}

	func listAllGroups(db: Database) async -> String{
		guard let groups = try? await DBGroup.query(on: db).all() else {
			assertionFailure()
			return ""
		}
		
        let values = groups.map{
			"\t-\"\($0.name)\":\"\($0.joinphrase)\" was last accessed at: " + ($0.lastAccess?.description  ?? "Unknown")
        }
        return values.joined(separator: "\n")
    }
}

//MARK: Support for creating joinphrases
extension GroupsManager{
    func createJoinPhrase(attemptsLeft: Int = 10) -> JoinPhrase?{
        guard attemptsLeft > 0 else{
            return nil
        }
        
		let phrase = joinPhraseGenerator()
		
		// If a phrase can be inserted without overwriting another element then it must be unique
		if reservedPhrases.insert(phrase).inserted {
			return phrase
		} else {
			//Otherwise we'll try again
            return createJoinPhrase(attemptsLeft: attemptsLeft - 1)
		}
	}
}
