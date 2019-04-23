//
//  AccountController.swift
//  App
//
//  Created by yuany on 2019/4/23.
//

import Foundation

final class AccountController: RouteCollection {
    func boot(router: Router) throws {
        let group = router.grouped(Api.Path.Account.group)
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let accountRouter = group.grouped([tokenAuthMiddleware, guardAuthMiddleware])
        accountRouter.get(Api.Path.Account.info, use: userInfo)
    }
}

private extension AccountController {
    func userInfo(_ req: Request) throws -> Future<Response> {
        let user = try req.requireAuthenticated(User.self)
        return try req.toJson(user)
    }
}
