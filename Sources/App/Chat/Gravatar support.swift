import Crypto

func getGravatarURLForUser(_ user: DBUser?, size: UInt? = nil) -> String{
	if let hash = user?.emailHash {
		return gravatarURLForHash(hash: hash, size: size)
	} else {
		return getDefaultGravatar(size: size)
	}
}

func getGravatarURLForInvite(_ user: InvitedUser?, size: UInt? = nil) -> String{
	if let hash = user?.emailHash {
		return gravatarURLForHash(hash: hash, size: size)
	} else {
		return getDefaultGravatar(size: size)
	}
}

private func gravatarURLForHash(hash: String, size: UInt?) -> String{
	let sParam: String
	if size != nil {
		sParam = "&s=\(size!)"
	} else {
		sParam = ""
	}
	
	return "https://www.gravatar.com/avatar/" + hash + "?d=mp" + sParam
}


func getDefaultGravatar(size: UInt? = nil)->String{
	let sParam: String
	if size != nil {
		sParam = "&s=\(size!)"
	} else {
		sParam = ""
	}
	return "https://www.gravatar.com/avatar?d=mp" + sParam
}

func getHashFor(_ email: String) -> String{
	let emailData = email.data(using: .utf8)!
	let hash = Insecure.MD5.hash(data: emailData).map {
		String(format: "%02hhx", $0)
	}.joined()
	
	return hash
}

