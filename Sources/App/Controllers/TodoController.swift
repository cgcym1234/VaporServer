import Vapor
import FluentSQLite

/// Controls basic CRUD operations on `Todo`s.
final class TodoController: RouteCollection {
	func boot(router: Router) throws {
//        let todos = router.grouped(Path.todos)
//        let tokenAuthGroup = todos.grouped(User.tokenAuthMiddleware(), User.guardAuthMiddleware())
//        
//        // Create
//        tokenAuthGroup.post(use: createHandler)
//        
//        //get
//        tokenAuthGroup.get(Todo.parameter, use: getHandler)
//        tokenAuthGroup.get(use: getAllHandler)
//        tokenAuthGroup.get(Path.search, use: searchHandler)
//        
//        tokenAuthGroup.put(Todo.parameter, use: updateHandler)
//        
//        tokenAuthGroup.delete(Todo.parameter, use: deleteHandler)
	}
}

private extension TodoController {
//    func createHandler(_ req: Request) throws -> Future<Todo.Public> {
//        let user = try req.requireAuthenticated(User.self)
//        return try req.content.decode(Todo.CreateRequest.self).flatMap {
//            let todo = try Todo(title: $0.title, isDone: false, userId: user.requireID())
//            try todo.validate()
//            return todo.save(on: req).public
//        }
//    }
//
//    func getHandler(_ req: Request) throws -> Future<Todo.Public> {
//        let user = try req.requireAuthenticated(User.self)
//        guard let todoId = req.parameters.values.first.flatMap({ Int($0.value) }) else {
//            throw Abort(.badRequest)
//        }
//
//        return try user
//            .children(\Todo.userId)
//            .query(on: req)
//            .filter(\.id == todoId).first().map(to: Todo.self, { (todo) in
//                guard let todo = todo else {
//                    throw Abort(.notFound)
//                }
//                return todo
//            }).public
//    }
//
//    func getAllHandler(_ req: Request) throws -> Future<[Todo.Public]> {
//        let user = try req.requireAuthenticated(User.self)
//        return try user.children(\Todo.userId)
//            .query(on: req)
//            .sort(\.createTime, .descending)
//            .decode(data: Todo.Public.self).all()
//    }
//
//    func searchHandler(_ req: Request) throws -> Future<[Todo.Public]> {
//        let user = try req.requireAuthenticated(User.self)
//        guard let query = req.query[String.self, at: "title"] else {
//            throw Abort(.badRequest)
//        }
//
//        return try user
//            .children(\Todo.userId)
//            .query(on: req)
//            .filter(\.title, .like, "%\(query)%")
//            .decode(data: Todo.Public.self)
//            .all()
//    }
//
//    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
//        let user = try req.requireAuthenticated(User.self)
//        guard let todoId = req.parameters.values.first.flatMap({ Int($0.value) }) else {
//            throw Abort(.badRequest)
//        }
//        return try user
//            .children(\Todo.userId)
//            .query(on: req)
//            .filter(\.id == todoId).first()
//            .flatMap(to: HTTPStatus.self) { (todo) in
//                guard let todo = todo else {
//                    throw Abort(.notFound)
//                }
//                return todo.delete(on: req).transform(to: .ok)
//        }
//    }
//
//    func updateHandler(_ req: Request) throws -> Future<Todo.Public> {
//        let user = try req.requireAuthenticated(User.self)
//        guard let todoId = req.parameters.values.first.flatMap({ Int($0.value) }) else {
//            throw Abort(.badRequest)
//        }
//
//        let todo =  try user
//            .children(\Todo.userId)
//            .query(on: req)
//            .filter(\.id == todoId).first().map(to: Todo.self, { (todo) in
//                guard let todo = todo else {
//                    throw Abort(.notFound)
//                }
//                return todo
//            })
//
//        return try flatMap(to: Todo.Public.self, todo, req.content.decode(Todo.UpdateRequest.self)) { (todo, updateTodo) in
//            if let title = updateTodo.title {
//                todo.title = title
//            }
//            if let isDone = updateTodo.isDone {
//                todo.isDone = isDone
//            }
//
//            try todo.validate()
//            return todo.save(on: req).public
//        }
//    }
}


