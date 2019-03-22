import Vapor
import Authentication

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    ///
    try router.register(collection: BoxueController())
    try router.register(collection: WebAuthController())
    try router.register(collection: BasicAuthController())
    
    let api = router.grouped(Path.api)
    try AuthController().boot(router: api)
//    try UserController().boot(router: api)
    try TodoController().boot(router: api)
    
    try LeafCRUD().boot(router: router)
    try JsonCRUD().boot(router: router)
}










