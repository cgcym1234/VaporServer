import Vapor
import Authentication

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    /// 2种注册方式，一样的
    try router.register(collection: BoxueController())
    try router.register(collection: WebAuthController())
    try router.register(collection: BasicAuthController())
    try router.register(collection: TokenAuthController())
    try router.register(collection: LeafCRUDController())
    try router.register(collection: JsonCRUDController())
    try router.register(collection: OneToManyControlelr())
    
    /// my demo
    let api = router.grouped(Api.Path.api)
    try AuthController().boot(router: api)
    try UserController().boot(router: api)
    try TodoController().boot(router: api)
}










