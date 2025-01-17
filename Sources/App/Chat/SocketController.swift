import Vapor
import Fluent
import VoteKit

fileprivate struct SocketWrapper{
    var socket: WebSocket
    var constituent: ConstituentIdentifier
    var isVerified: Bool
}

fileprivate enum Requestor: Hashable {
    case admin
    case consitutent(Constituent)
    var identitfier: String {
        switch self {
        case .admin: "Admin"
        case .consitutent(let constituent): constituent.identifier
        }
    }
}

actor ChatSocketController{
    private var sockets: [ConstituentIdentifier: SocketWrapper] = [:]
    private var adminSocket: WebSocket? = nil
    
    private let db: Database
    private var logger: Logger!
    
    private weak var group: Group?
    
    public init(db: Database) {
        self.db = db
    }
    
    func setup(group: Group) {
        self.group = group
        self.logger = Logger(label: "Chat socket controller: \(group.joinPhrase)")
    }
    
    private func remove(constituent: ConstituentIdentifier) async {
        sockets.removeValue(forKey: constituent)
    }
    
    func connect(_ ws: WebSocket, constituent: Constituent) async {
        guard let group = group else {return}
        
        ws.onBinary { [weak self] ws, buffer in
            guard let self, let data = buffer.getData(at: buffer.readerIndex, length: buffer.readableBytes) else { return }
            await self.onData(ws, requestor: .consitutent(constituent), data)
        }
        
        ws.onText { [weak self] ws, text in
            guard let self, let data = text.data(using: .utf8) else { return }
            await self.onData(ws, requestor: .consitutent(constituent), data)
        }
        ws.onClose.whenSuccess{
            Task{ [weak self] in
                await self?.remove(constituent: constituent.identifier)
            }
        }
        
        ws.pingInterval = .seconds(30)
        
        let isVerified = await group.constituentIsVerified(constituent)
        let wrapper = SocketWrapper(socket: ws, constituent: constituent.identifier, isVerified: isVerified)
        
        if let oldSocket = sockets.updateValue(wrapper, forKey: constituent.identifier){
            try? await oldSocket.socket.close()
        }
        
    }
    
    func connectAdmin(_ ws: WebSocket) async {
        if let oldSocket = adminSocket {
            try? await oldSocket.close()
        }
        
        ws.onBinary { [weak self] ws, buffer in
            guard let self = self, let data = buffer.getData(at: buffer.readerIndex, length: buffer.readableBytes) else { return }
            await self.onData(ws, requestor: .admin, data)
        }
        
        ws.onText { [weak self] ws, text in
            guard let self = self, let data = text.data(using: .utf8) else { return }
            await self.onData(ws, requestor: .admin, data)
        }
        ws.pingInterval = .seconds(30)
        adminSocket = ws
    }
    
    private func send(message: ServerChatProtocol, to sockets: [WebSocket]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(message)
            
            sockets.forEach {
                $0.send(raw: data, opcode: .binary)
            }
            
        } catch {
            logger.report(error: error)
        }
    }
    
    private func onData(_ ws: WebSocket, requestor: Requestor, _ data: Data) async {
        let decoder = JSONDecoder()
        guard let request = try? decoder.decode(ClientChatProtocol.self, from: data) else {
            if group == nil {
                kickAll(onlyUnverified: false, includeAdmins: true)
                return
            }
            
            sendER(error: .invalidRequest, to: ws)
            return
        }
        
        await handleRequest(request: request, socket: ws, requestor: requestor)
    }
    
    private func handleRequest(request: ClientChatProtocol, socket ws: WebSocket, requestor: Requestor) async {
        guard let group else {
            //Removes and closes all sockets if the group is no longer exsistent
            kickAll(onlyUnverified: false, includeAdmins: true)
            return
        }
        
        do {
            switch request{
            case .query:
                var qb = Chats
                    .query(on: db)
                    .filter(\.$groupID == group.id)
                    .sort(\.$timestamp, .descending)
                if requestor != .admin {
                    qb = qb.limit(Int(Config.chatQueryLimit))
                }
                
                let chats = try await qb.all()
                
                await self.send(message: .newMessages(chats.chatFormat(group: group)), to: ws)
            case .send(let newMsg):
                let msg = try checkMessage(msg: newMsg)
                
                if case let .consitutent(constituent) = requestor {
                    // Max n messages pr. m seconds pr. constituent
                    let time = Date().advanced(by: -Config.chatRateLimiting.seconds)
                    let count = try await Chats.query(on: db)
                        .filter(\.$groupID == group.id)
                        .filter(\.$sender == constituent.identifier)
                        .filter(\.$timestamp > time)
                        .count()
                    
                    if count >= Config.chatRateLimiting.messages {
                        sendER(error: .rateLimited, to: ws)
                        return
                    }
                }
                
                let chat = Chats(groupID: group.id, sender: requestor.identitfier, message: msg, systemsMessage: requestor == .admin)
                try await chat.save(on: db)
                
                Task {
                    let (name, imageURL): (String, String?) = switch requestor {
                    case .admin:
                        ("Admin", Config.adminProfilePicture)
                    case .consitutent(let constituent):
                        (constituent.getNameOrId(), await group.getGravatarURLForConst(constituent))
                    }
                    
                    guard let formatted = await chat.chatFormat(senderName: name, imageURL: imageURL) else {
                        return
                    }
                    sendToAll(msg: .newMessage(formatted))
                }
            }
        } catch let error as ChatError{
            sendER(error: error, to: ws)
        }
        catch {
            logger.report(error: error)
        }
    }
    
    func close(constituent: ConstituentIdentifier) async {
        do{
            try await self.sockets[constituent]?.socket.close()
        } catch{
            logger.error("Error while kicking \(constituent) from their chatsocket")
        }
    }
    
    func kickAll(onlyUnverified: Bool = false, includeAdmins: Bool = false) {
        assert(!(onlyUnverified && includeAdmins))
        
        var toClose = sockets.values.filter{!onlyUnverified || !$0.isVerified}.map(\.socket)
        
        if includeAdmins, let adminSocket {
            toClose.append(adminSocket)
        }
        
        Task{ [toClose] in
            for socket in toClose{
                do{
                    try await socket.close()
                } catch{
                    logger.error("Error while kicking all \(onlyUnverified ? "unverified" : "") from their chatsocket")
                }
                
            }
        }
        
    }
    
    func sendToAll(msg: ServerChatProtocol, includeAdmin: Bool = true) {
        var allSockets: [WebSocket] = sockets.values.map(\.socket)
        if includeAdmin, let adminSocket {
            allSockets.append(adminSocket)
        }
        
        send(message: msg, to: allSockets)
    }
    
    deinit {
        sockets.values.map(\.socket).forEach { $0.close(promise: nil) }
    }
}



extension ChatSocketController{
    func send(message: ServerChatProtocol, to socket: WebSocket){
        send(message: message, to: [socket])
    }
    
    func sendER(error: ChatError, to socket: WebSocket){
        send(message: .error(error), to: socket)
    }
}
