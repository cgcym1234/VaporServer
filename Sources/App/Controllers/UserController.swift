//
//  UserController.swift
//  App
//
//  Created by yangyuan on 2018/9/3.
//

import Vapor
import FluentSQL
import Crypto

final class UserController: RouteCollection {
    func boot(router: Router) throws {
        let users = router.grouped(Path.users)
        
        let tokenGroup = users.grouped(User.tokenAuthMiddleware(), User.guardAuthMiddleware())
        tokenGroup.get(use: getAllHandler)
        tokenGroup.put(use: updateHandler)
    }
}

// MARK: - Handlers
private extension UserController {
    func updateHandler(_ req: Request) throws -> Future<User.Public> {
        let user = try req.requireAuthenticated(User.self)
        return try req.content.decode(User.UpdateRequest.self).flatMap { updateRequest -> Future<User.Public> in
            if let email = updateRequest.email {
                user.email = email
            }
            if let name = updateRequest.name {
                user.name = name
            }
            if let password = updateRequest.password {
                user.password = try req.make(BCryptDigest.self).hash(password)
            }
            try user.validate()
            return user.save(on: req).public
        }
    }
    
    func getAllHandler(_ req: Request) throws -> Future<[User.Public]> {
        return User.query(on: req).decode(data: User.Public.self).all()
    }
}










