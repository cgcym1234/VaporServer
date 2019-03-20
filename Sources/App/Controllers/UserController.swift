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

extension UserController {
    func renderRegister(_ req: Request) throws -> Future<View> {
        return try req.view().render("register")
    }
    
    func register(_ req: Request) throws -> Future<Response> {
        return try req.content.decode(User.self).flatMap { user in
            
            return User.query(on: req).filter(\User.email == user.email).first().flatMap { result in
                if let _ = result {
                    return Future.map(on: req) {
                        return req.redirect(to: "/register")
                    }
                }
                
                user.password = try BCryptDigest().hash(user.password)
                
                return user.save(on: req).map { _ in
                    return req.redirect(to: "/login")
                }
            }
        }
    }
    
    func renderLogin(_ req: Request) throws -> Future<View> {
        return try req.view().render("login")
    }
    
    func login(_ req: Request) throws -> Future<Response> {
        return try req.content.decode(User.self).flatMap { user in
            return User.authenticate(
                username: user.email,
                password: user.password,
                using: BCryptDigest(),
                on: req
                ).map { user in
                    guard let user = user else {
                        return req.redirect(to: "/login")
                    }
                    
                    try req.authenticateSession(user)
                    return req.redirect(to: "/profile")
            }
        }
    }
    
    func renderProfile(_ req: Request) throws -> Future<View> {
        let user = try req.requireAuthenticated(User.self)
        return try req.view().render("profile", ["user": user])
    }
    
    func logout(_ req: Request) throws -> Future<Response> {
        try req.unauthenticateSession(User.self)
        return Future.map(on: req) { return req.redirect(to: "/login") }
    }
}









