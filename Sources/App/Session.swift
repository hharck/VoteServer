import Vapor

// Defines the 3 kinds of session a client can have

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

struct APISession: SessionAuthenticatable{
    var sessionID: SessionID = SessionID()
}

