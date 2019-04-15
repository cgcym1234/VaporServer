//
//  UserAuth.swift
//  App
//
//  Created by yuany on 2019/4/10.
//

import Foundation
import FluentMySQL
import Crypto
import Authentication


extension UserAuth {
    /// https://github.com/vapor/fluent-postgresql/issues/21
    enum AuthType: String, Content, MySQLEnumType {
        static func reflectDecoded() throws -> (UserAuth.AuthType, UserAuth.AuthType) {
            return (.email, .wxapp)
        }
        
        case email = "email"
        case wxapp = "wxapp" // 微信小程序
        
        static func type(_ val: String) -> AuthType {
            return AuthType(rawValue: val) ?? .email
        }
    }
}

/// 用该信息获取到 token
struct UserAuth: MySQLModel {
    var id: Int?
    var userId: User.ID
    var identityType: AuthType // 登录类型
    var identifier: String // 标志 (手机号，邮箱，用户名或第三方应用的唯一标识)
    var credential: String // 密码凭证(站内的保存密码， 站外的不保存或保存 token)
    
    var createdAt: Date?
    var updatedAt: Date?
    var deletedAt: Date?
    
    static var createdAtKey: TimestampKey? { return \.createdAt }
    static var updatedAtKey: TimestampKey? { return \.updatedAt }
    static var deletedAtKey: TimestampKey? { return \.deletedAt }
    
    init(userId: User.ID?, identityType: AuthType, identifier: String, credential: String) {
        self.userId = userId ?? 0
        self.identityType = identityType
        self.identifier = identifier
        self.credential = credential
    }
}

extension UserAuth {
    var user: Parent<UserAuth, User> {
        return parent(\.userId)
    }
}

extension UserAuth: Content {}
extension UserAuth: Migration {}

extension UserAuth: BasicAuthenticatable {
    static var usernameKey: WritableKeyPath<UserAuth, String> = \.identifier
    static var passwordKey: WritableKeyPath<UserAuth, String> = \.credential
}

extension UserAuth: Validatable {
    /// 只针对 email 的校验
    static func validations() throws -> Validations<UserAuth> {
        var validations = Validations(UserAuth.self)
        try validations.add(\.identifier, .email)
//        try validations.add(\.credential, .password)
        
        return validations
    }
}



















