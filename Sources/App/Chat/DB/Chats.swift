import Fluent
import Vapor
import VoteKit

final class Chats: Model, Content {
	static let schema = "Chats"
	
	@ID(key: .id)
	var id: UUID?
	
	@Parent(key: "group_and_sender")
	var groupAndSender: GroupConstLinker
	
	@Field(key: "message")
	var message: String
	
	@Field(key: "timestamp")
	var timestamp: Date
	
	@Field(key: "systems_message")
	var systemsMessage: Bool
	
	init(id: UUID? = nil, groupAndSender: GroupConstLinker, message: String, timestamp: Date = Date(), systemsMessage: Bool = false){
		self.id = id
		self.$groupAndSender.id = groupAndSender.id!
		self.message = message
		self.timestamp = timestamp
		self.systemsMessage = systemsMessage
	}
	
	init(){
		
	}
}


extension Chats{
	func chatFormat(senderName: String, imageURL: String?) async -> ChatFormat{
		guard self.id != nil else {
			fatalError("Attempted to access chat which hasn't been saved")
		}
				
		return ChatFormat(id: self.id!, sender: senderName, message: self.message, imageURL: imageURL, timestamp: self.timestamp, isSystemsMessage: self.systemsMessage)
	}
	
	func format() -> ChatFormat{
		var name = self.groupAndSender.constituent.name
		let imageURL: String
		if self.groupAndSender.isAdmin{
			name = "Admin - " + name
			imageURL = Config.adminProfilePicture
		} else {
			imageURL = getGravatarURLForUser(self.groupAndSender.constituent)
		}
		
		return ChatFormat(id: self.id!, sender: name, message: self.message, imageURL: imageURL, timestamp: self.timestamp, isSystemsMessage: self.systemsMessage)

	}
}

extension Array where Element == Chats{
	func chatFormat() async -> [ChatFormat]{
		var constituents = [String: (name: String, imageURL: String?)]()
		var output = [ChatFormat]()
		constituents["Admin"] = ("Admin", Config.adminProfilePicture)

		for chat in self{
			let sender = try! chat.joined(GroupConstLinker.self).joined(DBUser.self)
			if constituents[sender.username] == nil {
				let imageURL = getGravatarURLForUser(sender)
				let name = sender.name
				constituents[sender.username] = (name: name, imageURL: imageURL)
			}
			
			let c = constituents[sender.username]!
			
			output.append(ChatFormat(id: chat.id!, sender: c.name, message: chat.message, imageURL: c.imageURL, timestamp: chat.timestamp, isSystemsMessage: chat.systemsMessage))
		}
		return output
	}
	
}
