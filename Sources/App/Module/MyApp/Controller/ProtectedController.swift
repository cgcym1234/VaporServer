//
//  ProtectedController.swift
//  App
//
//  Created by yuany on 2019/4/25.
//

import Authentication

final class ProtectedController: RouteCollection {
    func boot(router: Router) throws {
        let group = router.grouped(Api.Path.Protected.group)
        
        ///In this specific case, the basicAuthMiddleware(using: BCrypt) is going to perform the actual validation of the Authorization headers. The guardAuthMiddleware is going to ensure an error is thrown (and the appropriate HTTP status code returned) if that authorization fails.
        let basicAuthMiddleware = UserAuth.basicAuthMiddleware(using: BCryptDigest())
        let basicGroup = group.grouped([basicAuthMiddleware, UserAuth.guardAuthMiddleware()])
        basicGroup.get(Api.Path.Protected.basic, use: basicAuth)
        
        /// App 采用这个
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let tokenGroup = group.grouped([tokenAuthMiddleware, User.guardAuthMiddleware()])
        tokenGroup.post(Api.Path.Protected.token, use: tokenAuth)
    }
}

private extension ProtectedController {
    func basicAuth(_ req: Request) throws -> Future<Response> {
        let user = try req.requireAuthenticated(User.self)
        return try req.toJson(with: user)
    }
    
    func tokenAuth(_ req: Request) throws -> Future<Response> {
        let user = try req.requireAuthenticated(User.self)
        return try req.toJson(with: user)
    }
}
