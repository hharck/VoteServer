import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
	app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

	// Adds support for using leaf to render views
    app.views.use(.leaf)
	
	
	// Adds support for sessions
	app.sessions.use(.memory)
	app.middleware.use(app.sessions.middleware)

	//Defines password hashing function
	app.passwords.use(.bcrypt)
	
    // register routes
    try routes(app)
}
