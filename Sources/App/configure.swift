import Leaf
import Vapor
import Fluent
import FluentSQLiteDriver

// configures your application
public func configure(_ app: Application) throws {
	let logger = Logger(label: "Config")
	// Set configuration variables from environment
	if app.environment == .testing {
		Config.setDefaultConfig()
	} else {
		Config.setGlobalConfig()
	}
	logger.info("Configured with: \(Config.config!)")
	
    // Allow static files to be served from /Public
	app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
	
	// Adds support for using leaf to render views
    app.views.use(.leaf)
	
	// DB
	app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)

	// Migrations
	app.migrations.add(CreateChats())
	app.migrations.add(CreateDBGroup())
	app.migrations.add(CreateUsers())
	app.migrations.add(CreateGroupConstLinker())
	app.migrations.add(CreateInvite())
	app.migrations.add(CreateInvitedUser())

	
	app.migrations.add(SessionRecord.migration)

	try app.autoMigrate().wait()
	
	
	// Enables sessions
	app.sessions.use(.fluent)
	app.middleware.use(app.sessions.middleware)

	// Defines password hashing function
	app.passwords.use(.bcrypt)
	
    
	let groupsManager = GroupsManager()

    // Enables CLI
    setupCommands(groupsManager: groupsManager, app: app)
    
	// Handle errors resulting in a redirect
	app.middleware.use(RedirectErrorHandler())
	app.middleware.use(RedirectUnauth())
	
    // Register routes
    try routes(app, groupsManager: groupsManager)
}
