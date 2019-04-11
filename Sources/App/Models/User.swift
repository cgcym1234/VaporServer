//
//  User.swift
//  App
//
//  Created by yangyuan on 2018/9/3.
//

import FluentMySQL
import Vapor
import Authentication

final class User: MySQLModel {
	var id: Int?
	
    var organizId: Organization.ID  // 公司
	var name: String
    var email: String?
    var avator: String?
    var info: String? // 简介
    
    var phone: String?
    var wechat: String? // 微信账号
    var qq: String? // qq 账号
    
    var password: String = ""
    
    var createdAt: Date?
    var updatedAt: Date?
    var deletedAt: Date?
    static var createdAtKey: TimestampKey? { return \.createdAt }
    static var updatedAtKey: TimestampKey? { return \.updatedAt }
    static var deletedAtKey: TimestampKey? { return \.deletedAt }
	
    init(name: String,
         phone: String? = nil,
         email: String? = nil,
         avator: String? = nil,
         organizId: Organization.ID? = nil,
         info: String? = nil) {
        self.name = name
        self.phone = phone
        self.email = email
        self.avator = avator
        self.organizId = organizId ?? 1
        self.info = info ?? "暂无简介"
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
    static func prepare(on conn: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: conn) { builder in
            try addProperties(to: builder)
//            builder.unique(on: \.email)
            builder.reference(from: \.organizId, to: \Organization.id)
        }
    }
}

extension User: TokenAuthenticatable {
    typealias TokenType = AccessToken
}


// MARK: - Customer
extension User {
	struct UpdateRequest: Content {
		var name: String?
		var email: String?
		var password: String?
	}
    
    struct Public: Content {
        let email: String
    }
}

