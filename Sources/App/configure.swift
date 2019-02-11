import FluentSQLite
import FluentMySQL
import Authentication
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register providers first
    try services.register(FluentSQLiteProvider())
	try services.register(FluentMySQLProvider())
	
	/// Configure the authentication provider
	try services.register(AuthenticationProvider())

    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

	///
	let directory = DirectoryConfig.detect()
	services.register(directory)
	
	// Configure a SQLite database
	//    let sqlite = try SQLiteDatabase(storage: .memory)
	let databasePath = directory.workDir + "todos.db"
	let sqlite = try SQLiteDatabase(storage: .file(path: databasePath))
	
	let mysqlConfig = MySQLDatabaseConfig(hostname: "mysql",
										  port: 3306,
										  username: "yuany",
										  password: "yuany",
										  database: "yuany",
										  transport: .unverifiedTLS)
	let mysql = MySQLDatabase(config: mysqlConfig)
	
    /// Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: sqlite, as: .sqlite)
	databases.add(database: mysql, as: .mysql)
    services.register(databases)

    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .sqlite)
	migrations.add(model: Token.self, database: .sqlite)
	migrations.add(model: Todo.self, database: .sqlite)
	migrations.add(model: Forum.self, database: .mysql)
    services.register(migrations)

	/// Configure command
	var command = CommandConfig.default()
	command.useFluentCommands()
	services.register(command)
}
