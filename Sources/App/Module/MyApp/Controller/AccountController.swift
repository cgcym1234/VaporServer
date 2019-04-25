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
        accountRouter.post(User.Update.self, at: Api.Path.Account.update, use: updateUser)
    }
}

private extension AccountController {
    func userInfo(_ req: Request) throws -> Future<Response> {
        let user = try req.requireAuthenticated(User.self)
        return try req.toJson(user)
    }
    
    func updateUser(_ req: Request, content: User.Update) throws -> Future<Response> {
        let user = try req.requireAuthenticated(User.self)
        user.avator = content.avator ?? user.avator
        user.name = content.name ?? user.name
        user.phone = content.phone ?? user.phone
        user.organizId = content.organizId ?? user.organizId
        user.info = content.info ?? user.info
        
        return try user.update(on: req).toJson(on: req)
    }
}
