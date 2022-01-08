import Vapor
import VoteKit

func adminRoutes(_ app: Application, groupsManager: GroupsManager) throws {
	app.get("voteadmin") { req async throws -> Response in
		//List of votes
		guard
			let sessionID = req.session.authenticated(AdminSession.self),
			let group = await groupsManager.groupForSession(sessionID)
		else {
			return req.redirect(to: .create)
		}
		
		return try await AdminUIController(for: group).encodeResponse(for: req)
	}
	
	// Changes the open/closed status of the vote passed as ":voteID"
	app.get("voteadmin", "open", ":voteID") { req async throws -> Response in
		await setStatus(req: req, status: .open)
	}
	app.get("voteadmin", "close", ":voteID") { req async throws -> Response in
		await setStatus(req: req, status: .closed)
	}
	
	
	func setStatus(req: Request, status: VoteStatus) async -> Response{
		if let voteIDStr = req.parameters.get("voteID"),
		   let sessionID = req.session.authenticated(AdminSession.self),
		   let group = await groupsManager.groupForSession(sessionID),
		   let vote = await group.voteForID(voteIDStr)
		{
            await group.setStatusFor(await vote.id(), to: status)
		}
		return req.redirect(to: .voteadmin)
	}
	
	// Shows an overview for a specific vote, with information such as who has voted and who has not
	app.get("voteadmin", ":voteID") { req async throws -> Response in
		guard let voteIDStr = req.parameters.get("voteID") else {
			return req.redirect(to: .voteadmin)
		}
		
		guard
			let sessionID = req.session.authenticated(AdminSession.self),
			let group = await groupsManager.groupForSession(sessionID),
			let vote = await group.voteForID(voteIDStr)
		else {
			return req.redirect(to: .voteadmin)
		}
		
        return try await VoteAdminUIController(vote: vote, group: group).encodeResponse(for: req)
            
	}
	
	app.post("voteadmin", ":voteID") { req async throws -> Response in
		guard let voteIDStr = req.parameters.get("voteID") else {
			return req.redirect(to: .voteadmin)
		}
		
		guard
			let adminID = req.session.authenticated(AdminSession.self),
			let group = await groupsManager.groupForSession(adminID),
			let vote = await group.voteForID(voteIDStr)
		else {
			return req.redirect(to: .voteadmin)
		}
		
		guard let status = (try req.content.decode([String:VoteStatus].self))["statusChange"] else {
			let pageController = await VoteAdminUIController(vote: vote, group: group)
			return try await pageController.encodeResponse(for: req)
		}
    
        
        await group.setStatusFor(await vote.id(), to: status)
		
		let pageController = await VoteAdminUIController(vote: vote, group: group)
		return try await pageController.encodeResponse(for: req)
	}
	
	// Shows a list of constituents and related settings
	app.get("voteadmin", "constituents") {req async throws -> Response in
		guard
			let sessionID = req.session.authenticated(AdminSession.self),
			let group = await groupsManager.groupForSession(sessionID)
		else {
			return req.redirect(to: .voteadmin)
		}
		
		return try await ConstituentsListUI(group: group).encodeResponse(for: req)
	}
	
	app.post("voteadmin", "constituents") {req async throws -> Response in
		guard
			let sessionID = req.session.authenticated(AdminSession.self),
			let group = await groupsManager.groupForSession(sessionID)
		else {
			return req.redirect(to: .constituents)
		}
		
		if let status = try? req.content.decode(ChangeVerificationRequirementsData.self).getStatus(){
			await group.setAllowsUnverifiedConstituents(status)
		}
		return try await ConstituentsListUI(group: group).encodeResponse(for: req)
	
		struct ChangeVerificationRequirementsData: Codable{
			private var setVerifiedRequirement: String
			func getStatus()->Bool?{
				if setVerifiedRequirement == "true"{
					return true
				} else if setVerifiedRequirement == "false"{
					return false
				} else {
					return nil
				}
			}
		}
	}
	
	app.get("voteadmin", "constituents", "downloadcsv") {req async throws -> Response in
		guard
			let sessionID = req.session.authenticated(AdminSession.self),
			let group = await groupsManager.groupForSession(sessionID)
		else {
			return req.redirect(to: .constituents)
		}
		
        let csv = await group.allPossibleConstituents().toCSV()
		return try await downloadResponse(for: req, content: csv, filename: "constituents.csv")

	}

	
	app.post("voteadmin", "resetaccess", ":userID"){req async throws -> Response in
		if let userIdentifierbase64 = req.parameters.get("userID")?.trimmingCharacters(in: .whitespacesAndNewlines),
           let userIdentifier = String(urlsafeBase64: userIdentifierbase64),
		   let sessionID = req.session.authenticated(AdminSession.self),
		   let group = await groupsManager.groupForSession(sessionID),
		   let constituent = await group.constituent(for: userIdentifier)
		{
			await group.resetConstituent(constituent)
		}
		
		return req.redirect(to: .constituents)

	}
	
	app.post("reset", ":voteID", ":userID") { req async -> Response in
		// Retrieves the vote id from the uri
		guard let voteIDStr = req.parameters.get("voteID") else {
			return req.redirect(to: .voteadmin)
		}
        
		// The single cast vote that should be deleted
		if let userIdentifierbase64 = req.parameters.get("userID")?.trimmingCharacters(in: .whitespacesAndNewlines),
           let userIdentifier = String(urlsafeBase64: userIdentifierbase64),
		   let adminID = req.session.authenticated(AdminSession.self),
		   let group = await groupsManager.groupForSession(adminID),
		   let vote = await group.voteForID(voteIDStr)
		{
            
            /// Removes a vote by the constituent in the group given in the URL; if the user has been kicked out, it will be removed from the vote's list of verified constituents
            func miniReset<V: SupportedVoteType>(vote: V) async{
                await vote.resetVoteForUser(userIdentifier)
                
                // If the user is no longer in the group, it'll be removed from the constituents list in the vote
                if await group.previouslyJoinedUnverifiedConstituents.contains(userIdentifier){
                    let constituent = Constituent(identifier: userIdentifier)
                    
                    let newConstitutents = await vote.constituents.filter{ const in
                        const != constituent
                    }
                    await vote.setConstituents(newConstitutents)
                }
            }
            
            switch vote {
            case .alternative(let v):
                await miniReset(vote: v)
            case .yesno(let v):
                await miniReset(vote: v)
            case .simplemajority(let v):
                await miniReset(vote: v)
            }
		}
		
		return req.redirect(to: .voteadmin(voteIDStr))
	}
	
	
	app.get("login"){ _ in
		LoginUI()
	}
	
	app.post("login"){req async -> Response in
		var joinPhrase: JoinPhrase?
		do{
			guard
				let loginData = try? req.content.decode([String: String].self),
				let pw = loginData["password"],
				let jf = loginData["joinPhrase"]
			else {
				throw "Invalid request"
			}
			joinPhrase = jf
			
			
			// Saves the group
			guard let session = await groupsManager.login(request: req, joinphrase: jf, password: pw) else{
				throw "No match for password and join code"
			}
			
			//Registers the session with the client
			req.session.authenticate(session)
			return req.redirect(to: .voteadmin)
			
		} catch {
			return (try? await LoginUI(prefilledJF: joinPhrase ?? "", errorString: error.asString()).encodeResponse(for: req)) ?? req.redirect(to: .login)
		}
	}
    
    
    app.get("admin", "settings"){ req async throws -> Response in
        guard
            let sessionID = req.session.authenticated(AdminSession.self),
            let group = await groupsManager.groupForSession(sessionID)
        else {
            return req.redirect(to: .create)
        }
        
        return try await SettingsUI(for: group).encodeResponse(for: req)
        
    }
}

struct SettingsUI: UITableManager{
    var title: String = "Settings"
    var errorString: String? = nil
    static var template: String = "settings"
    var buttons: [UIButton] = [.backToVoteadmin]
    
    var rows: [Setting]
    var tableHeaders: [String] = []
    
    init(for group: Group) async {
        self.rows = [
            Setting(1, "Allows unverified voters", state: await group.allowsUnverifiedConstituents),
            Setting(2, "Constituents can self reset", state: await group.constituentsCanSelfResetVotes),
//            Setting(3, "CSV Export mode", state: await group.CSVExportMode, mode: .list(["Default", "SMKid"])),
            ]
            .sorted(by: {$0.id < $1.id})
    }
    
    struct Setting: Codable{
        init(_ id: Int, _ name: String, state: Bool){
            self.id = id
            self.name = name
            self.state = state
        }
        
        var id: Int
        var name: String
        var state: Bool
    }
}
