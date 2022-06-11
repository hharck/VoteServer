import Vapor
import FluentKit

func userRoutes(_ path: RoutesBuilder){
	loginRoutes(path.grouped("login"))
	signupRoutes(path.grouped("signup"))
	
	#warning("Needs middleware")
	userPage(path.grouped(UserAuthenticator(), DBUser.guardMiddleware(throwing: Redirect(.login))))
	
	path.get("logout", use: logout)
}
//MARK: Logout
fileprivate func logout(req: Request) -> Response{
	req.session.destroy()
	return req.redirect(to: .login)
}

//MARK: User page
fileprivate func userPage(_ path: RoutesBuilder){
	path.get("user", use: userInfoPage)
	
	path.grouped("group", ":groupID").grouped(GroupAuthMiddleware(ignoreLinker: true)).get("accept", use:accept)

	
}

fileprivate func userInfoPage(req: Request) async throws -> UserUI{
	let user = try req.auth.require(DBUser.self)
	
	let name = user.name
	let username = user.username
	let email = user.email
	
	let allLinkers = try await user
		.$groups
		.query(on: req.db)
		.filter(\.$isBanned == false)
		.join(parent: \.$group)
		.all()

	return UserUI(name: name, username: username, email: email, linkers: allLinkers)
}


fileprivate func accept(req: Request) async throws -> Response{
	let user = try req.auth.require(DBUser.self)
	let group = try req.auth.require(DBGroup.self)
	
	guard
		let linker = try await user
			.$groups
			.query(on: req.db)
			.filter(\.$isBanned == false)
			.filter(\.$isCurrentlyIn == false)
			.filter(\.$group.$id == group.id!)
			.first()
	else {
		throw Abort(.unauthorized)
	}
	
	linker.isCurrentlyIn = true
	try await linker.save(on: req.db)
	
	return req.redirect(to: .plaza)
}


//MARK: Signup
fileprivate func signupRoutes(_ path: RoutesBuilder) {
	path.get(use: getSignup)
	path.post(use: doSignup)
}

fileprivate enum SignupError: ErrorString{
	case passwordsDoesntMatch
	case insecurePassword
	case invalidName
	case usernameInUse
	case emailInUse
	case invalidUsername
	
	func errorString() -> String {
		switch self {
		case .passwordsDoesntMatch:
			return "Passwords doesn't match"
		case .insecurePassword:
			return "Password is insecure"
		case .invalidName:
			return "Invalid name"
		case .usernameInUse:
			return "Username is already used"
		case .emailInUse:
			return "Email is already used"
		case .invalidUsername:
			return "Invalid username"
		}
	}
}

fileprivate func getSignup(req: Request) throws -> SignupUI{
	guard !req.auth.has(DBUser.self) else{
		throw Redirect(.user)
	}
	return SignupUI()
}

fileprivate func doSignup(req: Request) async throws -> SignupUI{
	struct SignupData: Codable, Validatable{
		let name: String
		let username: String
		let email: String
		let password: String
		let password2: String
		
		static func validations(_ validations: inout Validations){
			validations.add("email", 	as: String.self, is: .internationalEmail && .count(1...Int(Config.maxNameLength)))
			validations.add("name", 	as: String.self, is: .count(0...Int(Config.maxNameLength)))
			validations.add("password", as: String.self, is: .count(0...Int(Config.maxNameLength)))
			validations.add("username", as: String.self, is: .count(0...Int(Config.maxNameLength)) && .alphanumeric)
		}
	}
	
	
	var signupData: SignupData?
	do{
		
		signupData = try req.content.decode(SignupData.self)
		guard signupData!.password == signupData!.password2 else {
			throw SignupError.passwordsDoesntMatch
		}
		
		try SignupData.validate(content: req)
		
		let username = signupData!.username.lowercased()
		let name = signupData!.name.trimmingCharacters(in: .whitespacesAndNewlines)
		if name.contains("  ") || name.isEmpty || name.contains("\t") || name.count <= 1{
			throw SignupError.invalidName
		}
		if username.count <= 3{
			throw SignupError.invalidUsername
		}
		
		let email = signupData!.email.lowercased()
		
		
		// Checks password
		if signupData!.password.count < 7 {
			throw SignupError.insecurePassword
		}
		
		let forbiddenStrings = name.lowercased().split(separator: " ").map(String.init) + [username, "123", "321", "abc", "cba", "xyz", "qwe", "asd", "pass"]
		if forbiddenStrings.contains(where: signupData!.password.contains) {
			throw SignupError.insecurePassword
		}
		
		// Checks if any character is used 4 or more times
		if signupData!.password.nonUniques().contains(where: { char in signupData!.password.filter { $0 == char}.count > 3}){
			throw SignupError.insecurePassword
			
		}
		
		// Check uniqueness of username and email
		guard try await DBUser.query(on: req.db).filter(\.$email == email).count() == 0 else {
			throw SignupError.emailInUse
		}
		guard try await DBUser.query(on: req.db).filter(\.$username == username).count() == 0 else {
			throw SignupError.usernameInUse
		}
		
		let pwDigest = try await req.password.async.hash(signupData!.password).get()
		
		
		let user = DBUser(name: name, username: username, email: email, passwordDigest: pwDigest)
		try await user.save(on: req.db)
		req.session.authenticate(user)
		
		
	} catch {
		return SignupUI(prefilledName: signupData?.name, prefilledUN: signupData?.username, prefilledEmail: signupData?.email, errorString: error.asString())
	}
	
	throw Redirect(.user)
}

//MARK: Login

fileprivate func loginRoutes(_ path: RoutesBuilder) {
	path.get(use: getLogin)
	path.post(use: doLogin)
}

fileprivate enum LoginError: ErrorString{
	case unknownUsername
	case invalidPassword
	case incorrectCaptcha
	
	case invalidRequest
	
	func errorString() -> String {
		switch self {
		case .unknownUsername:
			return "Unknown username"
		case .invalidPassword:
			return "Incorrect password"
		case .incorrectCaptcha:
			return "The captcha wasn't solved"
		case .invalidRequest:
			return "Invalid request"
		}
	}
}


fileprivate func getLogin(req: Request) throws -> LoginUI{
	guard !req.auth.has(DBUser.self) else{
		throw Redirect(.user)
	}
	return LoginUI()
}


fileprivate func doLogin(req: Request) async throws -> Response{
	var username: String?
	do{
		guard
			let loginData = try? req.content.decode([String: String].self),
			let pw = loginData["password"],
			let un = loginData["username"]//,
//				let captchaResult = loginData["captcha"]
		else {
			throw LoginError.invalidRequest
		}
		username = un
		
		// Verify captcha
		
		#warning("Captcha not implemented")
		
		// Find user
		guard let user = try await DBUser
			.query(on: req.db)
			.filter(\.$username == un)
			.first() else {
			throw LoginError.unknownUsername
		}
		guard
			user.passwordDigest != nil,
			try await req.password.async.verify(pw, created: user.passwordDigest!).get()
		else {
			throw LoginError.invalidPassword
		}
		
		
		//Registers the session as a cookie on the client
		req.session.authenticate(user)
		return req.redirect(to: .user)
		
	} catch {
		return try await LoginUI(prefilledUN: username, errorString: error.asString()).encodeResponse(for: req)
	}
}
