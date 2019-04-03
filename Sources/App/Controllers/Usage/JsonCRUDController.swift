//
//  JsonCRUDController.swift
//  App
//
//  Created by yuany on 2019/3/21.
//

import Vapor


extension JsonCRUDController: RouteCollection {
    func boot(router: Router) throws {
        let sub = router.grouped(Path.api)
        
        sub.get(Path.users, use: list)
        sub.post(Path.users, use: create)
        
        /// users/#(id)
        sub.patch(Path.users, User.parameter, use: update)
        sub.delete(Path.users, User.parameter, use: delete)
    }
}

final class JsonCRUDController {
    func list(_ req: Request) throws -> Future<[User]> {
        return User.query(on: req).all()
    }
    
    func create(_ req: Request) throws -> Future<User> {
        return try req.content.decode(User.self).flatMap { user in
            return user.save(on: req)
        }
    }
    
    func update(_ req: Request) throws -> Future<User> {
        return try req.parameters.next(User.self).flatMap { user in
            return try req.content.decode(User.self).flatMap { newUser in
                user.update(with: newUser)
                return user.save(on: req)
            }
        }
    }
    
    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters
            .next(User.self)
            .flatMap { $0.delete(on: req) }
            .transform(to: .ok)
    }
}

extension JsonCRUDController {
    enum Path: String, PathComponentsRepresentable {
        case api = "json"
        case users
        
        var relativePath: String {
            switch self {
            case .api:
                return "/\(rawValue)"
            default:
                return "/\(Path.api.rawValue)/\(rawValue)"
            }
        }
        
        func convertToPathComponents() -> [PathComponent] {
            return [.init(stringLiteral: self.rawValue)]
        }
    }
}

