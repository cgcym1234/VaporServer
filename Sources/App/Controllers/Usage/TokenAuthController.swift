//
//  TokenAuthController.swift
//  App
//
//  Created by yuany on 2019/3/23.
//

import Authentication
import FluentSQLite
import Random

final class TokenAuthController: RouteCollection {
    func boot(router: Router) throws {
        let group = router.grouped(Path.api)
        
        ///curl -H "Content-Type: application/json" -X POST -d '{"email":"zelda@hyrule.com", "password": "link"}' http://localhost:8080/token/register
        group.post(Path.register, use: register)
        
        ///curl -H "Content-Type: application/json" -X POST -d '{"email":"zelda@hyrule.com", "password": "link"}' http://localhost:8080/token/login
        group.post(Path.login, use: login)
        
        let tokenAuth = TokenAuthUser.tokenAuthMiddleware()
        let authRoutes = group.grouped(tokenAuth)
        
        /// curl -H "Authorization: Bearer i4dl7fNpUD+iZuaUhbppMRRNM4m3ZNA/kxLMklcwjO8=" http://localhost:8080/token/profile
        authRoutes.get(Path.profile, use: profile)
        
        authRoutes.get(Path.logout, use: logout)
    }
}

private extension TokenAuthController {
    func register(_ req: Request) throws -> Future<TokenAuthUser.Public> {
        return try req.content
            .decode(TokenAuthUser.self)
            .flatMap { user in
                let hasher = try req.make(BCryptDigest.self)
                let password = try hasher.hash(user.password)
                let newUser = TokenAuthUser(email: user.email, password: password)
                
                return newUser.save(on: req).map {
                    TokenAuthUser.Public(id: try $0.requireID(), email: $0.email)
                }
        }
    }
    
    func login(_ req: Request) throws -> Future<TokenAuthToken> {
        return try req.content
            .decode(TokenAuthUser.self)
            .flatMap { user in
                return TokenAuthUser.query(on: req)
                    .filter(\.email == user.email)
                    .first()
                    .flatMap { fetchedUser in
                        guard let fetchedUser = fetchedUser else {
                            throw Abort(HTTPStatus.notFound)
                        }
                        
                        let hasher = try req.make(BCryptDigest.self)
                        if try hasher.verify(user.password, created: fetchedUser.password) {
                            /// 先删除再创建token
                            return try TokenAuthToken.query(on: req)
                                .filter(\.userId == fetchedUser.requireID())
                                .delete()
                                .flatMap { _ in
                                    let token = try URandom().generateData(count: 32).base64EncodedString()
                                    return try TokenAuthToken(token: token, userId: fetchedUser.requireID())
                                        .save(on: req)
                            }
                            
                        } else {
                            throw Abort(HTTPStatus.unauthorized)
                        }
                }
        }
    }
    
    func profile(_ req: Request) throws -> String {
        let user = try req.requireAuthenticated(TokenAuthUser.self)
        return "Welcome \(user.email)"
    }
    
    func logout(_ req: Request) throws -> Future<HTTPResponse> {
        let user = try req.requireAuthenticated(TokenAuthUser.self)
        return try TokenAuthToken.query(on: req)
            .filter(\.userId == user.requireID())
            .delete()
            .transform(to: HTTPResponse(status: .ok))
    }
}

extension TokenAuthController {
    enum Path: String, PathComponentsRepresentable {
        case api = "token"
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

final class TokenAuthUser: SQLiteModel {
    var id: Int?
    var email: String
    var password: String
    
    init(id: Int? = nil, email: String, password: String) {
        self.id = id
        self.email = email
        self.password = password
    }
}

extension TokenAuthUser {
    struct Public: Content {
        let id: Int
        let email: String
    }
}

extension TokenAuthUser: TokenAuthenticatable {
    typealias TokenType = TokenAuthToken
}

extension TokenAuthUser: Content {}
extension TokenAuthUser: Parameter {}
extension TokenAuthUser: Migration {}

// MARK: - TokenAuthToken
final class TokenAuthToken: SQLiteModel {
    var id: Int?
    var token: String
    var userId: TokenAuthUser.ID
    
    init(token: String, userId: User.ID) {
        self.token = token
        self.userId = userId
    }
}

extension TokenAuthToken {
    var user: Parent<TokenAuthToken, TokenAuthUser> {
        return parent(\.userId)
    }
}

extension TokenAuthToken: BearerAuthenticatable {
    static var tokenKey: WritableKeyPath<TokenAuthToken, String> = \.token
}

extension TokenAuthToken: Authentication.Token {
    typealias UserType = TokenAuthUser
    typealias UserIDType = TokenAuthToken.ID
    
    static var userIDKey: WritableKeyPath<TokenAuthToken, TokenAuthToken.ID> = \.userId
}

extension TokenAuthToken: Content {}
extension TokenAuthToken: Migration {}
extension TokenAuthToken: Parameter {}
