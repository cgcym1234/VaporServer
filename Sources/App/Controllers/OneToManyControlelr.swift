//
//  OneToManyControlelr.swift
//  App
//
//  Created by yuany on 2019/3/26.
//

import Foundation

final class OneToManyControlelr: RouteCollection {
    func boot(router: Router) throws {
        let group = router.grouped(Path.group)
        
        group.get(Path.users, use: list)
        group.post(Path.create, use: create)
        group.post(Path.delete, use: delete)
    }
}

private extension OneToManyControlelr {
    func list(_ req: Request) throws -> Future<View> {
        let allUsers = PokemonUser.query(on: req).all()
        return allUsers.flatMap { users in
            let userViewList = try users.map { user in
                return PokemonUser.View(user: user, pokemons: try user.pokemons.query(on: req).all())
            }
            
            let data = ["userViewList": userViewList]
            return try req.view().render(Leaf.oneToMany.name, data)
        }
    }
    
    
    func create(_ req: Request) throws -> Future<Response> {
        return try req.content.decode(Pokemon.Form.self)
            .flatMap { poekmonForm in
                return PokemonUser.find(poekmonForm.userId, on: req)
                    .flatMap { user in
                        guard let userId = try user?.requireID() else {
                            throw Abort(.badRequest)
                        }
                        
                        let pokenmon = Pokemon(name: poekmonForm.name, level: poekmonForm.level, userID: userId)
                        
                        return pokenmon.save(on: req).map { _ in
                            return req.redirect(to: Path.users.relativePath)
                        }
                }
        }
    }
    
    func delete(_ req: Request) throws -> Future<Response> {
        return try req.parameters.next(PokemonUser.self)
            .flatMap { user in
                try user.pokemons.query(on: req).delete().flatMap { _ in
                    return user.delete(on: req).map { _ in
                        req.redirect(to: Path.users.relativePath)
                    }
                }
        }
    }
}

private extension OneToManyControlelr {
    enum Leaf: String {
        case oneToMany
        
        var name: String {
            return rawValue
        }
    }
    
    enum Path: String, PathComponentsRepresentable {
        case group = "pokemon"
        case create
        case delete
        case users
        
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

final class PokemonUser: SQLiteModel {
    var id: Int?
    var email: String
    var password: String
    
    init(id: Int? = nil, email: String, password: String) {
        self.id = id
        self.email = email
        self.password = password
    }
    
    struct Form: Content {
        var username: String
    }
    
    struct View: Encodable {
        var user: PokemonUser
        var pokemons: Future<[Pokemon]>
    }
}

extension PokemonUser: Content {}
extension PokemonUser: Parameter {}
extension PokemonUser: Migration {}

extension PokemonUser {
    var pokemons: Children<PokemonUser, Pokemon> {
        return children(\.userID)
    }
}


final class Pokemon: SQLiteModel {
    var id: Int?
    var name: String
    var level: Int
    var userID: PokemonUser.ID
    
    init(id: Int? = nil, name: String, level: Int, userID: User.ID) {
        self.id = id
        self.name = name
        self.level = level
        self.userID = userID
    }
    
    struct Form: Content {
        var name: String
        var level: Int
        var userId: Int
    }
}

extension Pokemon: Content {}
extension Pokemon: Parameter {}
extension Pokemon: Migration {}

extension Pokemon {
    /// 使用Parent <Child，Parent>结构定义的关系，其中Pokemon类是子类，而User类是父类。现在访问属性（此处称为user）将返回可通过提供userID密钥路径找到的父级。Fluent知道对应关系的一切。它知道两个表：口袋妖怪和用户。从Pokemon那里我们可以获得具有属性userID背后的值的父级。
    
    ///这意味着每当我们有一个宠物小精灵实例时，总是能够通过访问用户属性来获取它的父级。
    var user: Parent<Pokemon, PokemonUser> {
        return parent(\.userID)
    }
}
