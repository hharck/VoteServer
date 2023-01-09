import Vapor
import VoteExchangeFormat
import FluentKit

func ChatRoutes(_ chat: RoutesBuilder, groupsManager: GroupsManager){
	chat.webSocket("socket", ":groupid", onUpgrade: joinChat)
	chat.webSocket("adminsocket", ":groupid", onUpgrade: joinChat)
	
	func joinChat(req: Request, socket: WebSocket) async{
		// Checks if the user is allowed to chat and whether the request is valid
		guard
			Config.enableChat,
			let user = try? req.auth.require(DBUser.self),
			let groupID = req.parameters.get("groupid"),
			let uuid = UUID(uuidString: groupID),
			let linker = try? await user
				.$groups
				.query(on: req.db)
				.join(parent: \.$group)
				.filter(\.$group.$id == uuid)
				.first(),
			linker.constituentCanChat()
		else {
			try? await socket.close()
			return
		}
		
		do{
			let dbGroup = try linker.joined(DBGroup.self)
			let group = await groupsManager.groupForGroup(dbGroup)
			
			let socketKind: ChatSocketController.SocketKind
			if req.url.path.hasSuffix("adminsocket/\(groupID)") {
				socketKind = .admin
			} else if req.url.path.hasSuffix("socket/\(groupID)") {
				if linker.isVerified{
					socketKind = .verified
				} else {
					socketKind = .unverified
				}
			} else {
				assertionFailure("This route should only be called with one of the two socket types above")
				try await socket.close()
				return
			}
			
			await group.socketController.connect(socket, userid: user.id!, socketKind: socketKind, db: req.db)
		} catch {
			try? await socket.close()
			return
		}
	}
}
