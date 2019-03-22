//
//  User.swift
//  App
//
//  Created by yangyuan on 2018/9/3.
//

import FluentSQLite
import Vapor
import Authentication

final class User: SQLiteModel {
	var id: Int?
	
	var name: String?
	var email: String
	var password: String
	
	init(id: Int? = nil, name: String?, email: String, password: String) {
		self.id = id
		self.name = name
		self.email = email
		self.password = password
	}
    
    func update(with model: User) {
        self.name = model.name
        self.email = model.email
        self.password = model.password
    }
}

extension User: Content {}
extension User: Parameter {}

extension User: Migration {
    static func prepare(on conn: SQLiteConnection) -> Future<Void> {
        return SQLiteDatabase.create(User.self, on: conn) { builder in
            try addProperties(to: builder)
            builder.unique(on: \.email)
        }
    }
}

extension User: Validatable {
	static func validations() throws -> Validations<User> {
		var validations = Validations(User.self)
		///Validates whether a `String` is a valid email address.
		try validations.add(\.email, .email)
		return validations
	}
}

extension User: PasswordAuthenticatable {
	static var usernameKey: WritableKeyPath<User, String> = \.email
	static var passwordKey: WritableKeyPath<User, String> = \.password
}

extension User: SessionAuthenticatable {}

extension User: TokenAuthenticatable {
	typealias TokenType = Token
}

// MARK: - Customer
extension User {
	struct UpdateRequest: Content {
		var name: String?
		var email: String?
		var password: String?
	}
}

extension User: PublicType {
	///
	struct Public: Content {
		var name: String?
		var email: String
	}
	
	var `public`: Public {
		return Public(name: name, email: email)
	}
}
