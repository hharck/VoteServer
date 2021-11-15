import Vapor
typealias SessionID = UUID
struct Session: SessionAuthenticatable{
	var sessionID: SessionID = SessionID()
}
