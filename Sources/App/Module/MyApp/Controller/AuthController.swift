//
//  AuthController.swift
//  App
//
//  Created by yangyuan on 2018/9/3.
//

import Vapor
import Crypto
import FluentSQLite
import Authentication

// 由于access_token默认有效时间为一小时, 所以每隔一小时需要点击从而刷新令牌,就是使用refresh_token 换取了一个新的 access_token.
// 由于access_token默认有效时间为一小时, refreshToken 有效期为三年,所以需要先获取refreshToken, 然后将其保存, 以后每次就可以不用去阿里云认证就可以用 refreshToken 换取 AccessToken
final class AuthController: RouteCollection {
    
    private let authService = AuthService()
    
    func boot(router: Router) throws {
        let group = router.grouped(Api.Path.Token.group)
        group.post(RefreshToken.Public.self, at: Api.Path.Token.refresh, use: refreshAccessTokenHandler)
        
        let basicAuthMiddleware = UserAuth.basicAuthMiddleware(using: BCryptDigest())
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let basiceAuthGroup = group.grouped([basicAuthMiddleware, guardAuthMiddleware])
        basiceAuthGroup.post(User.Email.self, at: Api.Path.Token.revoke, use: accessTokenRevokeHandler)
    }
}

private extension AuthController {
    func refreshAccessTokenHandler(req: Request, content: RefreshToken.Public) throws -> Future<Response> {
        return try authService.token(for: content.refreshToken, on: req)
    }
    
    func accessTokenRevokeHandler(req: Request, content: User.Email) throws -> Future<HTTPResponseStatus> {
        return try authService
            .revokeTokens(forEmail: content.email, on: req)
            .transform(to: .noContent)
    }
}
