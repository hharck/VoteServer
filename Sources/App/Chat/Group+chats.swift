import Fluent
extension GroupConstLinker{
	/// Checks if a constituent is allowed to chat
	/// - Parameter constituent: The constituent being checked
	/// - Returns: Whether the constituent is allowed
	func constituentCanChat() -> Bool {
		let chatState = try! self.joined(DBGroup.self).settings.chatState
		return Config.enableChat && chatState != .disabled && (self.isVerified || chatState == .forAll || self.isAdmin) && !self.isBanned && self.isCurrentlyIn
	}
}
