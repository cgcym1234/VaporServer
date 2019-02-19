import FluentSQLite
import FluentMySQL
import Authentication
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    
    func setupDatabase() throws {
        let directory = DirectoryConfig.detect()
        services.register(directory)
        
        let databasePath = directory.workDir + "todos.db"
        let sqlite = try SQLiteDatabase(storage: .file(path: databasePath))
        
        let mysqlHost: String
        let mysqlPort: Int
        let mysqlDB: String
        let mysqlUser: String
        let mysqlPass: String
        
        if env == .development || env == .testing {
            mysqlHost = "mysql"
            mysqlPort = 3306
            mysqlDB = "yuany"
            mysqlUser = "yuany"
            mysqlPass = "yuany"
        } else {
            print("Under production env")
            mysqlHost = Environment.get("MYSQL_HOST") ?? "mysql"
            mysqlPort = 3306
            mysqlDB = Environment.get("MYSQL_DB") ?? "yuany"
            mysqlUser = Environment.get("MYSQL_USER") ?? "yuany"
            mysqlPass = Environment.get("MYSQL_PASS") ?? "yuany"
        }
        
        let mysqlConfig = MySQLDatabaseConfig(hostname: mysqlHost,
                                              port: mysqlPort,
                                              username: mysqlUser,
                                              password: mysqlPass,
                                              database: mysqlDB,
                                              transport: .unverifiedTLS)
        let mysql = MySQLDatabase(config: mysqlConfig)
        
        /// Register the configured SQLite database to the database config.
        var databases = DatabasesConfig()
        databases.add(database: sqlite, as: .sqlite)
        databases.add(database: mysql, as: .mysql)
        
        services.register(databases)
    }
    
    func setupMigration() {
        /// Configure migrations
        var migrations = MigrationConfig()
        migrations.add(model: User.self, database: .sqlite)
        migrations.add(model: Token.self, database: .sqlite)
        migrations.add(model: Todo.self, database: .sqlite)
        migrations.add(model: Forum.self, database: .mysql)
        migrations.add(model: Message.self, database: .mysql)
        
        Forum.defaultDatabase = .mysql
        
        migrations.add(migration: Forum.Seeder.self, database: .mysql)
        migrations.add(migration: Message.Seeder.self, database: .mysql)
        
        services.register(migrations)
    }
    
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

    try setupDatabase()
    setupMigration()

	/// Configure command
	var command = CommandConfig.default()
	command.useFluentCommands()
	services.register(command)
}
