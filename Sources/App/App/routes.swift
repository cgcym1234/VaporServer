import Vapor
import Authentication

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    /// 2种注册方式，一样的
    try BoxueController().boot(router: router)
//    try router.register(collection: BoxueController())
    
    try router.register(collection: WebAuthController())
    try router.register(collection: BasicAuthController())
    try router.register(collection: TokenAuthController())
    try router.register(collection: LeafCRUDController())
    try router.register(collection: JsonCRUDController())
    try router.register(collection: OneToManyControlelr())
    
    /// my demo
    let api = router.grouped(Api.Path.group)
    try api.register(collection: AuthController())
    try api.register(collection: UserController())
    try api.register(collection: AccountController())
    try api.register(collection: BlogController())
    
    try TodoController().boot(router: api)
}










