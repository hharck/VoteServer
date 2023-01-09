import Vapor
import VoteKit
import Foundation
import FluentKit

func adminRoutes(_ path: RoutesBuilder, groupsManager: GroupsManager) {
	let admin = path.grouped(EnsureGroupAdmin()).grouped("admin")
	let voteadmin = path.grouped("voteadmin")

	voteCreationRoutes(admin.grouped("createvote"), groupsManager: groupsManager)
	
	voteadmin.redirectGet(to: .admin)
	
	admin.get(use: getAdminPage)
	func getAdminPage(req: Request) async throws -> AdminUIController {
		let dbGroup = try req.auth.require(DBGroup.self, Redirect(.create))
		let group = await groupsManager.groupForGroup(dbGroup)
		return await AdminUIController(for: group, settings: dbGroup.settings)
	}
    
	// Changes the open/closed status of the vote passed as ":voteID"
	voteadmin.get(":voteID", ":command", use: setStatus)
	func setStatus(req: Request) async throws -> Response{
		let group = await groupsManager.groupForGroup(try req.auth.require(DBGroup.self))
		if let voteIDStr = req.parameters.get("voteID"),
		   let commandStr = req.parameters.get("command"),
		   let command = VoteStatus(rawValue: commandStr),
		   let vote = await group.voteForID(voteIDStr)
		{
            await group.setStatusFor(await vote.id, to: command)
		}
		return req.redirect(to: .admin)
	}
	
	// Shows an overview for a specific vote, with information such as who has voted and who has not
	voteadmin.get(":voteID", use: postVoteAdmin)
	voteadmin.post(":voteID", use: postVoteAdmin)
	func postVoteAdmin(req: Request) async throws -> VoteAdminUIController {
		guard
            let voteIDStr = req.parameters.get("voteID"),
            let voteID = UUID(voteIDStr)
        else {
			throw Abort(.notFound)
		}
		
		let dbGroup = try req.auth.require(DBGroup.self)
		let group = await groupsManager.groupForGroup(dbGroup)
		guard let vote = await group.voteForID(voteID) else {
			throw Abort(.notFound)
		}
		
		if req.method == .POST {
			// Checks requests if they ask for deletion
			if let deleteID = (try? req.content.decode([String:String].self))?["voteToDelete"], voteIDStr == deleteID, await group.statusFor(voteID) == .closed {
				await group.removeVoteFromGroup(vote: vote)
				throw Redirect(.admin)
			}
			
			// Checks if any status change is requested
			if let status = (try? req.content.decode([String:VoteStatus].self))?["statusChange"] {
				await group.setStatusFor(await vote.id, to: status)
			}
		}
		
		return try await VoteAdminUIController(vote: vote, group: dbGroup, status: group.statusFor(vote) ?? .closed, db: req.db)
	}
	
	// Shows a list of constituents and related settings
	admin.get("constituents", use: constituentsPage)
	admin.post("constituents", use: constituentsPage)
	func constituentsPage(req: Request) async throws -> ConstituentsListUI  {
		let group = try req.auth.require(DBGroup.self, Abort(.notFound))
		let relatedGroup = await groupsManager.groupForGroup(group)
		
		if
			req.method == .POST,
			let status = try? req.content.decode(ChangeVerificationRequirementsData.self).getStatus()
		{
			try await group.updateUnverifiedSetting(status, relatedGroup: relatedGroup, db: req.db)
			try await group.save(on: req.db)
		}
		
		let constituents = try await group
			.$constituents
			.query(on: req.db)
			.filter(\.$isBanned == false)
			.join(parent: \.$constituent)
			.all()
		let invites = try await group
			.$invite
			.query(on: req.db)
			.join(parent: \.$invite)
			.all()
		
		return try await ConstituentsListUI(settings: group.settings, constituents: constituents, invites: invites)
		
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
	
	admin.get("constituents", "downloadcsv", use: downloadConstituentsCSV)
	func downloadConstituentsCSV(req: Request) async throws-> Response{
		let group = try req.auth.require(DBGroup.self, Redirect(.constituents))
		// Retrieve constituents from database
		let csv = try await group
			.$constituents
			.query(on: req.db)
			.join(parent: \.$constituent)
			.all()
		// Convert to constituents
			.asConstituents()
		// Convert to CSV
			.toCSV(config: group.settings.csvConfiguration)
		return try await downloadResponse(for: req, content: csv, filename: "constituents.csv")
	}
	
	admin.post("resetaccess", ":userID", use: resetaccess)
	func resetaccess(req: Request) async throws-> Response{
		let dbGroup = try req.auth.require(DBGroup.self)
		let group = await groupsManager.groupForGroup(dbGroup)
		
		if let userIdentifierbase64 = req.parameters.get("userID")?.trimmingCharacters(in: .whitespacesAndNewlines),
		   let userIdentifier = String(urlsafeBase64: userIdentifierbase64),
		   let const = try await dbGroup
			.$constituents
			.query(on: req.db)
			.join(parent: \.$constituent)
			.filter(DBUser.self, \DBUser.$username == userIdentifier)
			.first()
		{
			const.isCurrentlyIn = false
			await group.resetConstituent(const.asConstituent, userid: const.id!, isVerified: const.isVerified)
			try await const.save(on: req.db)
		}
		
		return req.redirect(to: .constituents)
	}
	voteadmin.post("reset", ":voteID", ":userID", use: resetAccessToVote)
	func resetAccessToVote(req: Request) async throws-> Response{
		// Retrieves the vote id from the uri
		guard let voteIDStr = req.parameters.get("voteID") else {
			throw Redirect(.admin)
		}
		let dbGroup = try req.auth.require(DBGroup.self)
		let group = await groupsManager.groupForGroup(dbGroup)
		
		// The single cast vote that should be deleted
		if let userIdentifierbase64 = req.parameters.get("userID")?.trimmingCharacters(in: .whitespacesAndNewlines),
		   let constituentID = String(urlsafeBase64: userIdentifierbase64),
		   let linker = try await dbGroup.$constituents
			.query(on: req.db)
			.filter(\.constituent.$username == constituentID)
			.first(),
			let vote = await group.voteForID(voteIDStr)
		{
			await group.singleVoteReset(vote: vote, linker: linker)
		}
		
		return req.redirect(to: .voteadmin(voteIDStr))
	}
	
    // The admin settings page
	admin.get("settings", use: getSettingsPage)
	func getSettingsPage(req: Request) async throws-> SettingsUI{
		let settings = try req.auth.require(DBGroup.self, Redirect(.create)).settings
		return await SettingsUI(current: settings)
	}
	
    // Requests for changing the settings of a group
	admin.post("settings", use: setSettings)
	func setSettings(req: Request) async throws-> SettingsUI{
		let dbGroup = try req.auth.require(DBGroup.self, Redirect(.create))
		let group = await groupsManager.groupForGroup(dbGroup)
		
		if let newSettings = try? req.content.decode(SetSettings.self){
			try await newSettings.saveSettings(to: dbGroup, ggroup: group, db: req.db)
		}
		
		return await SettingsUI(current: dbGroup.settings)
	}
	
	admin.get("chats", use: getAdminChatPage)
	func getAdminChatPage(req: Request) async throws -> AdminChatPage{
		let group = try req.auth.require(DBGroup.self, Redirect(.create))
		guard group.settings.chatState != .disabled else {
			throw Redirect(.admin)
		}
		return AdminChatPage()
	}
	
	admin.get("chats", "downloadcsv", use: downloadChats)
	func downloadChats(req: Request) async throws -> Response{
		guard Config.enableChat else {throw Abort(.notFound)}
		let group = try req.auth.require(DBGroup.self, Abort(.unauthorized))
		let groupID = try group.requireID()
		
		guard let allChats = try? await Chats
			.query(on: req.db)
			.filter(\Chats.groupAndSender.group.$id == groupID)
			.join(parent: \.$groupAndSender)
			.all() else {
			return Response(status: .internalServerError)
		}
		
		let header = "Sender,Message,Timestamp,Systems message\n"
		let content = allChats.map { chat -> String in
			[chat.groupAndSender.constituent.username, chat.message, "\(chat.timestamp)", "\(chat.systemsMessage ? 1 : 0)"]
				//Remove newlines and replace commas with "SINGLE LOW-9 QUOTATION MARK"
				.map{ str in
					str
						.replacingOccurrences(of: "\n", with: " ")
						.replacingOccurrences(of: ",", with: "‚")
						.trimmingCharacters(in: .whitespacesAndNewlines)
				}
				.joined(separator: ",")
		}.joined(separator: "\n")
		
		let csv = header + content
		return try await downloadResponse(for: req, content: csv, filename: "chathistory-\(group.joinphrase).csv")
	}
}

fileprivate struct SettingsUI: UITableManager{
    var title: String = "Settings"
    var errorString: String? = nil
	var generalInformation: HeaderInformation! = nil
    static var template: String = "settings"
	var buttons: [UIButton] = [.reload]
    
    var rows: [Setting]
    var tableHeaders: [String] = []
    
    
    init(current: GroupSettings) async {
        self.rows = [
            Setting("auv", "Allow unverified constituents", type: .bool(current: current.allowsUnverifiedConstituents), disclaimer: current.allowsUnverifiedConstituents ? "Changing this setting will kick unverified constituents" : nil),
            Setting("selfReset", "Constituents can reset their votes", type: .bool(current: current.constituentsCanSelfResetVotes)),
            Setting("CSVConfiguration", "CSV Export mode", type: .list(options: Array(GroupSettings.csvKeys.keys), current: current.csvConfiguration.name)),
			Setting("showTags", "Show tags", type: .bool(current: current.showTags)),
            ]
		if Config.enableChat{
			self.rows.append(Setting("chat", "Allow livechat", type: .list(options: GroupSettings.ChatState.allCases.map(\.rawValue), current: current.chatState.rawValue)))
		}
    }
    
    struct Setting: Codable{
        init(_ key: String, _ name: String, type: SettingsType, disclaimer: String? = nil){
            self.key = key
            self.name = name
            self.type = type
            self.disclaimer = disclaimer
        }
        
        var key: String
        var name: String
        var type: SettingsType
        var disclaimer: String?
        
        enum SettingsType: Codable{
            case bool(current: Bool)
            case list(options: [String], current: String)
        }
    }
}


struct SetSettings: Codable{
    var auv: String?
    var selfReset: String?
	var showTags: String?
    var CSVConfiguration: String?
	var chat: GroupSettings.ChatState?
	
	func saveSettings(to group: DBGroup, ggroup: Group, db: Database) async throws{
		try await group.updateUnverifiedSetting(convertBool(auv), relatedGroup: ggroup, db: db)
		group.settings.constituentsCanSelfResetVotes = convertBool(selfReset)
		group.settings.showTags = convertBool(showTags)
		
		if
			let key = CSVConfiguration,
			let rConfig = GroupSettings.csvKeys[key]
		{
			group.settings.csvConfiguration = rConfig
		}
		
		if chat != nil && Config.enableChat {
			switch chat{
			case .onlyVerified:
				await ggroup.socketController.kickAll(only: .unverified)
			case .disabled:
				await ggroup.socketController.kickAll()
			default:
				break
			}
			
			group.settings.chatState = chat!
		}
		
		
		try await group.save(on: db)
    }
    // Due to limitations of HTTP/HTML the state of checkboxes is only sent when they're on
    private func convertBool(_ value: String?) -> Bool{
        switch value{
        case "on":
            return true
        default:
            return false
        }
    }
}
