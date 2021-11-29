import Vapor
typealias SessionID = UUID
struct AdminSession: SessionAuthenticatable{
	var sessionID: SessionID = SessionID()
}

struct VoterSession: SessionAuthenticatable{
	var sessionID: SessionID = SessionID()
}

struct GroupSession: SessionAuthenticatable{
	var sessionID: SessionID
}
