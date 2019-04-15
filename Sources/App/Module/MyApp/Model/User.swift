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

extension User {
    var codes: Children<User, ActiveCode> {
        return children(\.userId)
    }
    
    /// 组织
    var organization: Parent<User, Organization> {
        return parent(\.organizId)
    }
}


// MARK: - Customer
extension User: PublicType {
    struct Public: Content {
        let email: String
    }
    
    var `public`: Public {
        return Public(email: email!)
    }
}

extension User {
    struct Email: Content {
        let email: String
    }
    
    struct EmailLogin: Content {
        var email: String
        var password: String
    }
    
    struct Register: Content {
        let email: String
        let password: String
        let name: String
        let organizId: Organization.ID?
    }
    
    struct RegisterCode: Content {
        let code: String
        let userId: User.ID
    }
    
    struct NewPassword: Content {
        let email: String
        let password: String
        let newPassword: String
        let code: String
    }
}

extension User {
    struct WXAppOAuth: Content {
        let encryptedData: String
        let iv: String
        let code: String
    }
    
    struct WXAppResponse: Content {
        var sessionKey: String
        var expiresIn: TimeInterval
        var openid: String
    }
    
    /// openId : 用户在当前小程序的唯一标识
    struct WXApp: Content {
        var openId: String
        var nickName: String
        var city: String
        var province: String
        var country: String
        var avatarUrl: String
        var unionId: String? // 如果开发者拥有多个移动应用、网站应用、和公众帐号（包括小程序），可通过unionid来区分用户的唯一性，因为只要是同一个微信开放平台帐号下的移动应用、网站应用和公众帐号（包括小程序），用户的unionid是唯一的。换句话说，同一用户，对同一个微信开放平台下的不同应用，unionId是相同的
        var watermark: WaterMark
        
        struct WaterMark: Content {
            var appid: String
            var timestamp: TimeInterval
        }
    }
}
