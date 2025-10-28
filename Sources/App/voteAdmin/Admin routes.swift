import Vapor
import VoteKit
import Foundation
import FluentKit

func adminRoutes(_ app: Application, groupsManager: GroupsManager) {
    let admin = app.grouped("admin")
    let voteadmin = app.grouped("voteadmin")
    let login = app.grouped("login")

    voteadmin.redirectGet(to: .admin)

    admin.get(use: getAdminPage)
    @Sendable func getAdminPage(req: Request) async -> ResponseOrRedirect<AdminUIController> {
        // List of votes
        guard
            let sessionID = req.session.authenticated(AdminSession.self),
            let group = await groupsManager.groupForSession(sessionID)
        else {
            return .redirect(.create)
        }

        return await .response(AdminUIController(for: group))
    }

    // Changes the open/closed status of the vote passed as ":voteID"
    voteadmin.get(":voteID", ":command", use: setStatus)
    @Sendable func setStatus(req: Request) async -> Response {
        if let voteIDStr = req.parameters.get("voteID"),
           let commandStr = req.parameters.get("command"),
           let command = VoteStatus(rawValue: commandStr),
           let sessionID = req.session.authenticated(AdminSession.self),
           let group = await groupsManager.groupForSession(sessionID),
           let vote = await group.voteForID(voteIDStr) {
            await group.setStatusFor(await vote.id(), to: command)
        }
        return req.redirect(to: .admin)
    }

    // Shows an overview for a specific vote, with information such as who has voted and who has not
    voteadmin.get(":voteID", use: postVoteAdmin)
    voteadmin.post(":voteID", use: postVoteAdmin)
    @Sendable func postVoteAdmin(req: Request) async -> ResponseOrRedirect<VoteAdminUIController> {
        guard
            let voteIDStr = req.parameters.get("voteID"),
            let voteID = UUID(voteIDStr)
        else {
            return .redirect(.admin)
        }

        guard
            let adminID = req.session.authenticated(AdminSession.self),
            let group = await groupsManager.groupForSession(adminID),
            let vote = await group.voteForID(voteID)
        else {
            return .redirect(.admin)
        }

        if req.method == .POST {
            // Checks requests if they ask for deletion
            if let deleteID = (try? req.content.decode([String: String].self))?["voteToDelete"], voteIDStr == deleteID, await group.statusFor(voteID) == .closed {
                await group.removeVoteFromGroup(vote: vote)
                return .redirect(.admin)
            }

            // Checks if any status change is requested
            if let status = (try? req.content.decode([String: VoteStatus].self))?["statusChange"] {
                await group.setStatusFor(await vote.id(), to: status)
            }

        }
        return await .response(VoteAdminUIController(vote: vote, group: group))
    }

    // Shows a list of constituents and related settings
    admin.get("constituents", use: constituentsPage)
    admin.post("constituents", use: constituentsPage)
    @Sendable func constituentsPage(req: Request) async -> ResponseOrRedirect<ConstituentsListUI> {
        guard
            let sessionID = req.session.authenticated(AdminSession.self),
            let group = await groupsManager.groupForSession(sessionID)
        else {
            return .redirect(.admin)
        }

        if req.method == .POST,
           let status = try? req.content.decode(ChangeVerificationRequirementsData.self).getStatus() {
            await group.setSettings(allowsUnverifiedConstituents: status)
        }

        return await .response(ConstituentsListUI(group: group))

        struct ChangeVerificationRequirementsData: Codable {
            private var setVerifiedRequirement: String
            func getStatus() -> Bool? {
                switch setVerifiedRequirement {
                case "true": true
                case "false": false
                default: nil
                }
            }
        }
    }

    admin.get("constituents", "downloadcsv", use: downloadConstituentsCSV)
    @Sendable func downloadConstituentsCSV(req: Request) async -> ResponseOrRedirect<String> {
        guard
            let sessionID = req.session.authenticated(AdminSession.self),
            let group = await groupsManager.groupForSession(sessionID)
        else {
            return .redirect(.constituents)
        }

        let csv = await group.allPossibleConstituents().toCSV(config: group.settings.csvConfiguration)
        return downloadResponse(for: req, content: csv, filename: "constituents.csv")
    }

    admin.get("constituents", "downloadcurrentlyin", use: downloadCurrentlyInCSV)
    @Sendable func downloadCurrentlyInCSV(req: Request) async -> ResponseOrRedirect<String> {
        guard
            let sessionID = req.session.authenticated(AdminSession.self),
            let group = await groupsManager.groupForSession(sessionID)
        else {
            return .redirect(.constituents)
        }

        let csv = await group.joinedConstituentsByID.values.toCSV(config: group.settings.csvConfiguration)
        return downloadResponse(for: req, content: csv, filename: "joined-constituents.csv")
    }

    admin.post("resetaccess", ":userID", use: resetaccess)
    @Sendable func resetaccess(req: Request) async -> Response {
        if let userIdentifierbase64 = req.parameters.get("userID")?.trimmingCharacters(in: .whitespacesAndNewlines),
           let userIdentifier = String(urlsafeBase64: userIdentifierbase64),
           let sessionID = req.session.authenticated(AdminSession.self),
           let group = await groupsManager.groupForSession(sessionID),
           let constituent = await group.constituent(for: userIdentifier) {
            await group.resetConstituent(constituent)
        }

        return req.redirect(to: .constituents)
    }
    voteadmin.post("reset", ":voteID", ":userID", use: resetAccessToVote)
    @Sendable func resetAccessToVote(req: Request) async -> Response {
        // Retrieves the vote id from the uri
        guard let voteIDStr = req.parameters.get("voteID") else {
            return req.redirect(to: .admin)
        }

        // The single cast vote that should be deleted
        if let userIdentifierbase64 = req.parameters.get("userID")?.trimmingCharacters(in: .whitespacesAndNewlines),
           let constituentID = String(urlsafeBase64: userIdentifierbase64),
           let adminID = req.session.authenticated(AdminSession.self),
           let group = await groupsManager.groupForSession(adminID),
           let vote = await group.voteForID(voteIDStr) {
            await group.singleVoteReset(vote: vote, constituentID: constituentID)
        }

        return req.redirect(to: .voteadmin(voteIDStr))
    }

    login.get(use: getLogin)
    @Sendable func getLogin(req: Request) async -> LoginUI {
        let showRedirectToPlaza = await groupsManager.groupAndVoterForReq(req: req) != nil
        return LoginUI(showRedirectToPlaza: showRedirectToPlaza)
    }
    login.post(use: doLogin)
    @Sendable func doLogin(req: Request) async -> ResponseOrRedirect<LoginUI> {
        guard
            let loginData = try? req.content.decode([String: String].self),
            let pw = loginData["password"],
            let joinPhrase = loginData["joinPhrase"]
        else {
            let showRedirectToPlaza = await groupsManager.groupAndVoterForReq(req: req) != nil
            return .response(LoginUI(prefilledJoinPhrase: "", errorString: "Invalid request", showRedirectToPlaza: showRedirectToPlaza))
        }

        // Saves the group
        guard let session = await groupsManager.login(request: req, joinphrase: joinPhrase, password: pw) else {
            let showRedirectToPlaza = await groupsManager.groupAndVoterForReq(req: req) != nil

            return .response(LoginUI(prefilledJoinPhrase: joinPhrase, errorString: "No match for password and join code", showRedirectToPlaza: showRedirectToPlaza))
        }

        // Registers the session with the client
        req.session.authenticate(session)
        return .redirect(.admin)
    }
    // The admin settings page
    admin.get("settings", use: getSettingsPage)
    @Sendable func getSettingsPage(req: Request) async -> ResponseOrRedirect<SettingsUI> {
        guard
            let sessionID = req.session.authenticated(AdminSession.self),
            let group = await groupsManager.groupForSession(sessionID)
        else {
            return .redirect(.create)
        }

        return await .response(SettingsUI(for: group))
    }

    // Requests for changing the settings of a group
    admin.post("settings", use: setSettings)
    @Sendable func setSettings(req: Request) async -> ResponseOrRedirect<SettingsUI> {
        guard
            let sessionID = req.session.authenticated(AdminSession.self),
            let group = await groupsManager.groupForSession(sessionID)
        else {
            return .redirect(.create)
        }

        if let newSettings = try? req.content.decode(SetSettings.self) {
            await newSettings.saveSettings(to: group)
        }

        return await .response(SettingsUI(for: group))
    }

    admin.get("chats", use: getAdminChats)
    @Sendable func getAdminChats(req: Request) async -> ResponseOrRedirect<AdminChatPage> {
        guard
            let sessionID = req.session.authenticated(AdminSession.self),
            let group = await groupsManager.groupForSession(sessionID)
        else {
            return .redirect(.create)
        }
        guard await group.settings.chatState != .disabled else {
            return .redirect(.admin)
        }
        return .response(AdminChatPage())
    }
    admin.get("chats", "downloadcsv", use: downloadChats)
    @Sendable func downloadChats(req: Request) async throws(Abort) -> ResponseOrRedirect<String> {
        guard
            Config.enableChat,
            let sessionID = req.session.authenticated(AdminSession.self),
            let group = await groupsManager.groupForSession(sessionID)

        else {
            throw Abort(.unauthorized)
        }

        guard let allChats = try? await Chats
            .query(on: req.db)
            .filter(\.$groupID == group.id)
            .all() else {
            throw Abort(.internalServerError)
        }

        let header = "Sender,Message,Timestamp,Systems message\n"
        let content = allChats.map { chat -> String in
            [chat.sender, chat.message, "\(chat.timestamp)", "\(chat.systemsMessage ? 1 : 0)"].joined(separator: ",")
        }.joined(separator: "\n")

        let csv = header + content
        return downloadResponse(for: req, content: csv, filename: "chathistory-\(group.joinPhrase).csv")
    }
}

private struct SettingsUI: UITableManager {
    var title: String = "Settings"
    var errorString: String?
    static let template: String = "settings"
    var buttons: [UIButton] = [.backToAdmin, .reload]

    var rows: [Setting]
    var tableHeaders: [String] = []

    init(for group: Group) async {
        let current = await group.settings
        self.rows = [
            Setting("auv", "Allow unverified constituents", type: .bool(current: current.allowsUnverifiedConstituents), disclaimer: current.allowsUnverifiedConstituents ? "Changing this setting will kick unverified constituents" : nil),
            Setting("selfReset", "Constituents can reset their votes", type: .bool(current: current.constituentsCanSelfResetVotes)),
            Setting("CSVConfiguration", "CSV Export mode", type: .list(options: Array(current.csvKeys.keys), current: current.csvConfiguration.name)),
            Setting("showTags", "Show tags", type: .bool(current: current.showTags)),
        ]
        if Config.enableChat {
            self.rows.append(Setting("chat", "Allow livechat", type: .list(options: GroupSettings.ChatState.allCases.map(\.rawValue), current: current.chatState.rawValue)))
        }
    }

    struct Setting: Codable {
        init(_ key: String, _ name: String, type: SettingsType, disclaimer: String? = nil) {
            self.key = key
            self.name = name
            self.type = type
            self.disclaimer = disclaimer
        }

        var key: String
        var name: String
        var type: SettingsType
        var disclaimer: String?

        enum SettingsType: Codable {
            case bool(current: Bool)
            case list(options: [String], current: String)
        }
    }
}

struct SetSettings: Codable {
    var auv: String?
    var selfReset: String?
    var CSVConfiguration: String?
    var showTags: String?
    var chat: GroupSettings.ChatState?

    func saveSettings(to group: Group) async {
        let rAUV = convertBool(auv)
        let rSelfReset = convertBool(selfReset)
        let rShowTags = convertBool(showTags)

        let rConfig: CSVConfiguration?
        if let key = CSVConfiguration {
            rConfig = await group.settings.csvKeys[key]
        } else {
            rConfig = nil
        }

        await group.setSettings(allowsUnverifiedConstituents: rAUV, constituentsCanSelfResetVotes: rSelfReset, csvConfiguration: rConfig, showTags: rShowTags, chatState: chat)
    }
    // Due to limitations of HTTP/HTML the state of checkboxes is only sent when they're on
    private func convertBool(_ value: String?) -> Bool {
        switch value {
        case "on":
            return true
        default:
            return false
        }
    }
}
