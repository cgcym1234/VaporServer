import FluentSQLite
import Vapor

/// A single entry of a Todo list.
final class Todo: SQLiteModel {
	/// The unique identifier for this `Todo`.
	var id: Int?
	
	/// A title describing what this `Todo` entails.
	var title: String
	
	/// Whether this `Todo` is done or not
	var isDone: Bool
	
	/// The date when this `Todo` was created
	var createTime: Date
	
	/// Reference to user that owns this todo.
	var userId: User.ID
	
	init(id: Int? = nil, title: String, isDone: Bool, userId: User.ID) {
		self.id = id
		self.title = title
		self.isDone = isDone
		self.userId = userId
		self.createTime = Date()
	}
}

/// Allows `Todo` to be used as a dynamic migration.
extension Todo: Migration { }

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
extension Todo: Content { }

/// Allows `Todo` to be used as a dynamic parameter in route definitions.
extension Todo: Parameter { }

extension Todo: Validatable {
	static func validations() throws -> Validations<Todo> {
		var vals = Validations(Todo.self)
		try vals.add(\.title, .count(1...))
		return vals
	}
}

extension Todo {
	struct CreateRequest: Content {
		var title: String
		var isDone: Bool?
	}
	
	struct UpdateRequest: Content {
		var title: String?
		var isDone: Bool?
	}
}

extension Todo: PublicType {
	struct Public: Content {
		var id: Int?
		var title: String
		var isDone: Bool
		var createTime: Date
	}
	
	var `public`: Public {
		return Public(id: id, title: title, isDone: isDone, createTime: createTime)
	}
}
