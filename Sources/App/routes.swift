import Vapor
import Authentication

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    let api = router.grouped(Path.api)
    
    try router.register(collection: BoxueController())
    
    try AuthController().boot(router: api)
    try UserController().boot(router: api)
    try TodoController().boot(router: api)
    
    let user = UserController()
    router.get("register", use: user.renderRegister)
    router.post("register", use: user.register)
    router.get("login", use: user.renderLogin)
    
    let authSessionRouter = router.grouped(User.authSessionsMiddleware())
    authSessionRouter.post("login", use: user.login)
    
    let protectedRouter = authSessionRouter.grouped(RedirectMiddleware<User>(path: "/login"))
    protectedRouter.get("profile", use: user.renderProfile)
    
    router.get("logout", use: user.logout)
}










