//
//  WebAuthController.swift
//  App
//
//  Created by yuany on 2019/3/22.
//

import Authentication
import FluentSQLite

final class WebAuthController: RouteCollection {
    func boot(router: Router) throws {
        let webAuth = router.grouped(Path.api)
        
        webAuth.get(Path.register, use: renderRegister)
        webAuth.post(Path.register, use: register)
        webAuth.get(Path.login, use: renderLogin)
        webAuth.get(Path.logout, use: logout)
        
        let authSessionRouter = webAuth.grouped(WebAuthUser.authSessionsMiddleware())
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
        return try req.content.decode(WebAuthUser.self).flatMap { user in
            return WebAuthUser.authenticate(
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
        let user = try req.requireAuthenticated(WebAuthUser.self)
        return try req.view().render("profile", ["user": user])
    }
    
    func logout(_ req: Request) throws -> Future<Response> {
        try req.unauthenticateSession(WebAuthUser.self)
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


struct WebAuthUser: SQLiteModel {
    var id: Int?
    var email: String
    var password: String
    
    init(id: Int? = nil, email: String, password: String) {
        self.id = id
        self.email = email
        self.password = password
    }
}

extension WebAuthUser: Content {}
extension WebAuthUser: Migration {}

extension WebAuthUser: PasswordAuthenticatable {
    static var usernameKey: WritableKeyPath<WebAuthUser, String> = \.email
    static var passwordKey: WritableKeyPath<WebAuthUser, String> = \.password
}

extension WebAuthUser: SessionAuthenticatable {}
