//
//  AuthController.swift
//  App
//
//  Created by yangyuan on 2018/9/3.
//

import Vapor
import Crypto
import FluentSQLite

final class AuthController: RouteCollection {
	func boot(router: Router) throws {
		let auth = router.grouped(Path.auth)
		// Create new user
		auth.post(User.self, at: Path.register, use: registerHandler)
		
		/// Login
		let authMid = User.basicAuthMiddleware(using: BCryptDigest())
		let authGroup = auth.grouped(authMid)
		authGroup.post(Path.login, use: loginHandler)
	}
}

private extension AuthController {
	func registerHandler(req: Request, user: User) throws -> Future<User.Public> {
		try user.validate()
		let digest = try req.make(BCryptDigest.self)
		let hashedPassword = try digest.hash(user.password)
		user.password = hashedPassword
		return user.save(on: req).public
	}
	
	func loginHandler(_ req: Request) throws -> Future<Token.Public> {
		guard let user = try? req.requireAuthenticated(User.self) else {
			throw Abort(.unauthorized, reason: "Invalid email or password")
		}
		return try Token.create(userId: user.requireID()).save(on: req).public
	}
}
