//
//  BasicAuthController.swift
//  App
//
//  Created by yuany on 2019/3/22.
//

import Authentication
import FluentSQLite

final class BasicAuthController: RouteCollection {
    func boot(router: Router) throws {
        let group = router.grouped(Path.group)
        
        ///curl -H "Content-Type: application/json" -X POST -d '{"email":"zelda@hyrule.com", "password": "myheroislink"}' http://localhost:8080/basic/register
        group.post(Path.register, use: register)
        
        ///echo -n "zelda@hyrule.com:myheroislink" | base64
        ///emVsZGFAaHlydWxlLmNvbTpteWhlcm9pc2xpbms=
        /// curl -H "Authorization: Basic emVsZGFAaHlydWxlLmNvbTpteWhlcm9pc2xpbms=" -X POST http://localhost:8080/basic/login
        let middleWare = BasicUser.basicAuthMiddleware(using: BCryptDigest())
        let authedGroup = group.grouped(middleWare)
        authedGroup.post(Path.login, use: login)
        
        /// curl -H "Authorization: Basic emVsZGFAaHlydWxlLmNvbTpteWhlcm9pc2xpbms=" http://localhost:8080/basic/profile
        authedGroup.get(Path.profile, use: profile)
    }
}

private extension BasicAuthController {
    func register(_ req: Request) throws -> Future<BasicUser.Public> {
        return try req.content
            .decode(BasicUser.self)
            .flatMap { user in
                let hasher = try req.make(BCryptDigest.self)
                let password = try hasher.hash(user.password)
                let newUser = BasicUser(email: user.email, password: password)
                
                return newUser.save(on: req).map {
                    BasicUser.Public(id: try $0.requireID(), email: $0.email)
                }
        }
    }
    
    func login(_ req: Request) throws -> BasicUser.Public {
        let user = try req.requireAuthenticated(BasicUser.self)
        return BasicUser.Public(id: try user.requireID(), email: user.email)
    }
    
    func profile(_ req: Request) throws -> String {
        let user = try req.requireAuthenticated(BasicUser.self)
        return "You're viewing \(user.email) profile."
    }
}

extension BasicAuthController {
    enum Path: String, PathComponentsRepresentable {
        case group = "basic"
        case register
        case login
        case profile
        case logout
        
        var relativeValue: String {
            switch self {
            case .group:
                return rawValue
            default:
                return "\(Path.group.rawValue)/\(rawValue)"
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

final class BasicUser: SQLiteModel {
    var id: Int?
    var email: String
    var password: String
    
    init(id: Int? = nil, email: String, password: String) {
        self.id = id
        self.email = email
        self.password = password
    }
}

extension BasicUser {
    struct Public: Content {
        let id: Int
        let email: String
    }
}

extension BasicUser: BasicAuthenticatable {
    static var usernameKey: WritableKeyPath<BasicUser, String> = \.email
    static var passwordKey: WritableKeyPath<BasicUser, String> = \.password
}

extension BasicUser: Content {}
extension BasicUser: Parameter {}
extension BasicUser: Migration {}
