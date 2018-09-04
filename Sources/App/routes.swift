import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
	let api = router.grouped(Path.api)
	
	try AuthController().boot(router: api)
	try UserController().boot(router: api)
	try TodoController().boot(router: api)
}
