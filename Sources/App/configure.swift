import Leaf
import Vapor
import Fluent
import FluentSQLiteDriver

// configures your application
@MainActor
public func configure(_ app: Application) throws {
    let logger = Logger(label: "Config")
    // Set configuration variables from environment
    if app.environment == .testing {
        Config.setDefaultConfig()
    } else {
        Config.setGlobalConfig()
    }
    guard let config = Config.config else {
        fatalError()
    }
    logger.info("Configured with: \(config)")

    // Allow static files to be served from /Public
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // Adds support for using leaf to render views
    app.views.use(.leaf)
    app.leaf.tags["version"] = VersionTag()

    // DB
#if os(macOS)
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
#else
    do {
        logger.info("Attempting to store database on the file system")
        try FileManager.default.createDirectory(atPath: "persistence/", withIntermediateDirectories: true, attributes: nil)
        app.databases.use(.sqlite(.file("persistence/db.sqlite")), as: .sqlite)
    } catch {
        logger.error("Unable to store database due to the following error: \(error.localizedDescription)")
        logger.info("Using in-memory database")

        app.databases.use(.sqlite(.memory), as: .sqlite)
    }
#endif

    app.migrations.add(CreateChats())
    app.migrations.add(SessionRecord.migration)

    try app.autoMigrate().wait()

    // Enables sessions
    app.sessions.use(.memory)
    app.middleware.use(app.sessions.middleware)

    // Defines password hashing function
    app.passwords.use(.bcrypt)

    let groupsManager = GroupsManager()

    // Enables CLI
    setupCommands(groupsManager: groupsManager, app: app)

    // Register routes
    routes(app, groupsManager: groupsManager)
}
