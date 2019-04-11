//
//  RefreshToken.swift
//  App
//
//  Created by yuany on 2019/4/10.
//

import Foundation
import FluentMySQL
import Crypto

extension RefreshToken: PublicType {
    typealias Token = String
    
    struct Public: Content {
        let refreshToken: Token
    }
    
    var `public`: Public {
        return Public(refreshToken: token)
    }
}

struct RefreshToken: MySQLModel {
    var id : Int?
    let token: Token
    let userId: Int
    
    var createdAt: Date?
    var updatedAt: Date?
    var deletedAt: Date?
    
    static var createdAtKey: TimestampKey? { return \.createdAt }
    static var updatedAtKey: TimestampKey? { return \.updatedAt }
    static var deletedAtKey: TimestampKey? { return \.deletedAt }
    
    init(userId: Int) throws {
        self.token = try CryptoRandom().generateData(count: 32).base64EncodedString()
        self.userId = userId
    }
}

extension RefreshToken: Content {}
extension RefreshToken: Migration {}
