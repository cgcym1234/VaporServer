//
//  Token.swift
//  App
//
//  Created by yangyuan on 2018/9/3.
//

import Authentication
import FluentSQLite
import Vapor

final class Token: Content, Parameter, SQLiteModel {
	/// Token's unique identifier.
	var id: Int?
	
	/// Unique token string.
	var token: String
	
	/// Expiration date. Token will no longer be valid after this point.
	var expires: Date?
	
	/// Reference to user that owns this token.
	var userId: User.ID
	
	init(id: Int? = nil, token: String, userId: User.ID) {
		self.id = id
		self.token = token
		
		// set token to expire after 30 days
		self.expires = Date(timeInterval: 60 * 60 * 24 * 30, since: .init())
		
		self.userId = userId
	}
	
	static var deletedAtKey: TimestampKey? {
		return \.expires
	}
}

extension Token: Migration { }

extension Token: Authentication.Token {
	typealias UserType = User
	static var tokenKey: WritableKeyPath<Token, String> = \.token
	static var userIDKey: WritableKeyPath<Token, User.ID> = \.userId
}

extension Token {
	static func create(userId: User.ID) throws -> Token {
		let token = try CryptoRandom().generateData(count: 64).base64EncodedString()
		return .init(token: token, userId: userId)
	}
}

extension Token: PublicType {
	struct Public: Content {
		var token: String
		var expires: Date?
		var userId: User.ID
	}
	
	var `public`: Public {
		return Public(token: token, expires: expires, userId: userId)
	}
}
