import FluentSQLite
import FluentMySQL
import Authentication
import Vapor
import Leaf

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    try setupRouter(&services)
    
    try setupLeaf(&config, &services)
    
    try setupDatabase(&env, &services)
    try setupMigration(&services)
    try setupCommand(&services)
    
    try setupMiddleware(&config, &services)
    
    try setupAuth(&services)
    
//    try setupConfig(&services)
}

private func setupRouter(_ services: inout Services) throws {
    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)
}

private func setupLeaf(_ config: inout Config, _ services: inout Services) throws {
    let leafProvider = LeafProvider()
    try services.register(leafProvider)
    config.prefer(LeafRenderer.self, for: ViewRenderer.self)
}

private func setupDatabase(_ env: inout Environment, _ services: inout Services) throws {
    /// Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    
    /// SQLite
    try services.register(FluentSQLiteProvider())
    
    let directory = DirectoryConfig.detect()
    services.register(directory)
    
    let databasePath = directory.workDir + "todos.db"
    let sqlite = try SQLiteDatabase(storage: .file(path: databasePath))
    databases.add(database: sqlite, as: .sqlite)
    
    /// MySQL
    try services.register(FluentMySQLProvider())
    
    let mysqlHost: String
    let mysqlPort: Int
    let mysqlDB: String
    let mysqlUser: String
    let mysqlPass: String
    
    if env == .development || env == .testing {
        mysqlHost = "0.0.0.0"
        mysqlPort = 33060
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
    databases.add(database: mysql, as: .mysql)
    
    services.register(databases)
}

private func setupMigration(_ services: inout Services) throws {
    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .sqlite)
    migrations.add(model: Token.self, database: .sqlite)
    migrations.add(model: Todo.self, database: .sqlite)
    
    migrations.add(model: BasicUser.self, database: .sqlite)
    migrations.add(model: TokenUser.self, database: .sqlite)
    migrations.add(model: TokenToken.self, database: .sqlite)
    migrations.add(model: Pokemon.self, database: .sqlite)
    
    migrations.add(model: Forum.self, database: .mysql)
    migrations.add(model: Message.self, database: .mysql)
    
    Forum.defaultDatabase = .mysql
    
    migrations.add(migration: Forum.Seeder.self, database: .mysql)
    migrations.add(migration: Message.Seeder.self, database: .mysql)
    
    services.register(migrations)
}

private func setupCommand(_ services: inout Services) throws {
    /// Configure command
    var command = CommandConfig.default()
    command.useFluentCommands()
    services.register(command)
}

private func setupMiddleware(_ config: inout Config, _ services: inout Services) throws {
    /// Register middleware
    var middlewares = MiddlewareConfig.default() // Create _empty_ middleware config
    middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    middlewares.use(SessionsMiddleware.self)
    services.register(middlewares)
    
    config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)
}

private func setupConfig(_ services: inout Services) throws {
    /// 更改项目的端口
    let myService = NIOServerConfig.default(port: 8001)
    services.register(myService)
}

private func setupAuth(_ services: inout Services) throws {
     /// Configure the authentication provider
    try services.register(AuthenticationProvider())
}

