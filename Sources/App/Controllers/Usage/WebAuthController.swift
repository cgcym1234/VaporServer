//
//  WebAuthController.swift
//  App
//
//  Created by yuany on 2019/3/22.
//

import Authentication

final class WebAuthController: RouteCollection {
    func boot(router: Router) throws {
        let webAuth = router.grouped(Path.api)
        
        webAuth.get(Path.register, use: renderRegister)
        webAuth.post(Path.register, use: register)
        webAuth.get(Path.login, use: renderLogin)
        webAuth.get(Path.logout, use: logout)
        
        let authSessionRouter = webAuth.grouped(User.authSessionsMiddleware())
        authSessionRouter.post(Path.login, use: login)
        
        let protectedRouter = authSessionRouter.grouped(RedirectMiddleware<User>(path: Path.login.relativePath))
        protectedRouter.get(Path.profile, use: renderProfile)
    }
}

private extension WebAuthController {
    func renderRegister(_ req: Request) throws -> Future<View> {
        return try req.view().render(Leaf.register.name)
    }
    
    func register(_ req: Request) throws -> Future<Response> {
        return try req.content
            .decode(User.self)
            .flatMap { user in
                return User.query(on: req)
                    .filter(\.email == user.email)
                    .first()
                    .flatMap { result in
                        if let _ = result {
                            return Future.map(on: req) {
                                req.redirect(to: Path.register.relativePath)
                            }
                        }
                        
                        user.password = try BCryptDigest().hash(user.password)
                        return user.save(on: req).map { _ in
                            req.redirect(to: Path.login.relativePath)
                        }
                }
        }
    }
    
    func renderLogin(_ req: Request) throws -> Future<View> {
        return try req.view().render(Leaf.login.name)
    }
    
    func login(_ req: Request) throws -> Future<Response> {
        return try req.content.decode(User.self).flatMap { user in
            return User.authenticate(
                username: user.email,
                password: user.password,
                using: BCryptDigest(),
                on: req)
                .map { user in
                    guard let user = user else {
                        return req.redirect(to: Path.login.relativePath)
                    }
                    
                    try req.authenticateSession(user)
                    return req.redirect(to: Path.profile.relativePath)
            }
        }
    }
    
    func renderProfile(_ req: Request) throws -> Future<View> {
        let user = try req.requireAuthenticated(User.self)
        return try req.view().render("profile", ["user": user])
    }
    
    func logout(_ req: Request) throws -> Future<Response> {
        try req.unauthenticateSession(User.self)
        return Future.map(on: req) { req.redirect(to: Path.logout.relativePath) }
    }
}

extension WebAuthController {
    enum Path: String, PathComponentsRepresentable {
        case api = "web"
        case register
        case login
        case profile
        case logout
        
        var relativeValue: String {
            switch self {
            case .api:
                return rawValue
            default:
                return "\(Path.api.rawValue)/\(rawValue)"
            }
        }
        
        var relativePath: String {
            return "/" + relativeValue
        }
        
        func convertToPathComponents() -> [PathComponent] {
            return [.init(stringLiteral: rawValue)]
        }
    }
}


extension WebAuthController {
    enum Leaf: String {
        case register
        case login
        case profile
        
        var name: String {
            return rawValue
        }
    }
}
