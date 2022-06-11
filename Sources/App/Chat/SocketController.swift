import Vapor
import VoteKit
import FluentKit
import Foundation

actor ChatSocketController{
	enum SocketKind: String{
		case unverified, verified, admin
	}
	
	fileprivate struct SocketWrapper{
		var socket: WebSocket
		var userid: UUID
		var socketKind: SocketKind
	}
	
	private var sockets: [UUID: SocketWrapper] = [:]

	private var logger: Logger!
	
	/// Id of the related group
	private var groupID: UUID
	
	init(_ group: DBGroup){
		self.groupID = group.id!
		self.logger = Logger(label: "Chat socket controller: \(group.joinphrase)")
	}
	
	
	
	
	
	private func remove(userid: UUID) async{
		sockets.removeValue(forKey: userid)
	}
	
	func connect(_ ws: WebSocket, userid: UUID, socketKind: SocketKind, db: Database) async {
		ws.onBinary { [weak self] ws, buffer in
			guard let self = self, let data = buffer.getData(at: buffer.readerIndex, length: buffer.readableBytes) else { return }
			await self.onData(ws, userid: userid, data, db: db)
		}
		ws.onText { [weak self] ws, text in
			guard let self = self, let data = text.data(using: .utf8) else { return }
			await self.onData(ws, userid: userid, data, db: db)
		}
		ws.onClose.whenSuccess{
			Task{ [weak self] in
				await self?.remove(userid: userid)
			}
		}

		ws.pingInterval = .seconds(30)
		
		
		let wrapper = SocketWrapper(socket: ws, userid: userid, socketKind: socketKind)
				
		if let oldSocket = sockets.updateValue(wrapper, forKey: userid){
			try? await oldSocket.socket.close()
		}
		
		try? await doQuery(db, socketKind == .admin, ws)
	}

	private func send(message: ServerChatProtocol, to sockets: [WebSocket]){
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
	
	
	private func onData(_ ws: WebSocket, userid: UUID, _ data: Data, db: Database) async {
		let decoder = JSONDecoder()
		guard let request = try? decoder.decode(ClientChatProtocol.self, from: data) else {
			sendER(error: .invalidRequest, to: ws)
			return
		}
				
		await handleRequest(request: request, socket: ws, userid: userid, db: db)
	}
	
	fileprivate func doQuery(_ db: Database, _ isAdmin: Bool, _ ws: WebSocket) async throws {
		var qb = Chats
			.query(on: db)
			.join(parent: \.$groupAndSender)
			.filter(GroupConstLinker.self, \.$group.$id == groupID)
			.join(from: GroupConstLinker.self, parent: \.$constituent)
			.sort(\.$timestamp, .descending)
		
		if !isAdmin{
			qb = qb.limit(Int(Config.chatQueryLimit))
		}
		
		let chats = try await qb.all()
		
		
		await self.send(message: .newMessages(chats.chatFormat()), to: ws)
	}
	
	private func handleRequest(request: ClientChatProtocol, socket ws: WebSocket, userid: UUID, db: Database) async{

		do {
			
			guard let dbGroup = try await DBGroup.find(groupID, on: db) else {
				logger.error("Group not found for socket request")
				self.kickAll()
				return
			}
			
			guard
				let user = try await dbGroup
					.$constituents
					.query(on: db)
					.join(parent: \.$constituent)
					.filter(\.$constituent.$id == userid)
					.first()
			else {
				logger.error("User not found for socket request")
				return
			}
			
			let isAdmin = user.isAdmin
			
			
			switch request{
			case .query:
				try await doQuery(db, isAdmin, ws)
			case .send(let newMsg):
				let msg = try checkMessage(msg: newMsg)
				
				if !user.isAdmin{
					// Max n messages pr. m seconds pr. constituent
					let time = Date().advanced(by: -Config.chatRateLimiting.seconds)
					let count = try await Chats.query(on: db)
						.filter(\.$groupAndSender.$id == userid)
						.filter(\.$timestamp > time)
						.count()
					
					if count >= Config.chatRateLimiting.messages {
						sendER(error: .rateLimited, to: ws)
						return
					}
				}
				
				let chat = Chats(groupAndSender: user, message: msg, systemsMessage: user.isAdmin)
				try await chat.$groupAndSender.load(on: db)
				try await chat.groupAndSender.$constituent.load(on: db)
				try await chat.save(on: db)
				let formatted = chat.format()
				await sendToAll(msg: .newMessage(formatted))

				
			}
		} catch let error as ChatError{
			sendER(error: error, to: ws)
		}
		catch {
			logger.report(error: error)
		}
	}
	
	func close(userid: UUID) async{
		do{
			try await self.sockets[userid]?.socket.close()
		} catch{
			logger.error("Error while kicking \(userid) from their chatsocket")
		}
	}
	
	func kickAll(only kind: SocketKind? = nil){
		let toClose = self.sockets
			.values
			.filter{kind == nil || $0.socketKind == kind}
			.map(\.socket)
		
		Task{ [toClose] in
			for socket in toClose{
				do{
					try await socket.close()
				} catch{
					logger.error("Error while kicking \(kind?.rawValue ?? "all") from their chatsocket")
				}
				
			}
		}
		
	}
	
	func sendToAll(msg: ServerChatProtocol, async: Bool = false, includeAdmin: Bool = true) async{
		if async{
			Task{ [weak self] in
				guard let self = self else {return}
				let allSockets: [WebSocket] = await self
					.sockets
					.values
					.filter{includeAdmin || $0.socketKind != .admin}
					.map(\.socket)
				
				await self.send(message: msg, to: allSockets)
				
			}
		} else {
			let allSockets: [WebSocket] = self
				.sockets
				.values
				.filter{includeAdmin || $0.socketKind != .admin}
				.map(\.socket)
			self.send(message: msg, to: allSockets)
		}
	}
	
	deinit{
		Task{
			await self.kickAll()
		}
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
