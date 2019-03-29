//
//  LeafCRUDController.swift
//  App
//
//  Created by yuany on 2019/3/21.
//

import Vapor

extension LeafCRUDController: RouteCollection {
    func boot(router: Router) throws {
        let sub = router.grouped(Path.leaf)
        
        sub.get(Path.users, use: list)
        sub.post(Path.users, use: create)
        
        /// users/#(id)/update
        sub.post(Path.users, User.parameter, "udpate", use: update)
        sub.post(Path.users, User.parameter, "delete", use: delete)
    }
}

final class LeafCRUDController {
    func list(_ req: Request) throws -> Future<View> {
        let allUsers = User.query(on: req).all()
        
        return allUsers.flatMap { users in
            return try req.view().render(Leaf.crud.name, ["userlist": users])
        }
    }
    
    func create(_ req: Request) throws -> Future<Response> {
        return try req.content.decode(User.self).flatMap { user in
            return user.save(on: req).map { _ in
                return req.redirect(to: Path.users.relativePath)
            }
        }
    }
    
    func update(_ req: Request) throws -> Future<Response> {
        return try req.parameters.next(User.self)
            .flatMap { user in
                return user.save(on: req).map { _ in
                    return req.redirect(to: Path.users.relativePath)
                }
        }
    }
    
    func delete(_ req: Request) throws -> Future<Response> {
        return try req.parameters.next(User.self)
            .flatMap { user in
                return user.delete(on: req).map { _ in
                    return req.redirect(to: Path.users.relativePath)
                }
        }
    }
}


private extension LeafCRUDController {
    enum Leaf: String {
        case crud
        
        var name: String {
            return rawValue
        }
    }
    
    enum Path: String, PathComponentsRepresentable {
        case leaf
        case users
        
        
        var relativePath: String {
            switch self {
            case .leaf:
                return "/\(rawValue)"
            default:
                return "/\(Path.leaf.rawValue)/\(rawValue)"
            }
        }
        
        func convertToPathComponents() -> [PathComponent] {
            return [.init(stringLiteral: self.rawValue)]
        }
    }
}

