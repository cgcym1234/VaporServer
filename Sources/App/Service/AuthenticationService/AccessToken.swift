//
//  AccessToken.swift
//  App
//
//  Created by yuany on 2019/4/10.
//

import Foundation
import FluentMySQL
import Crypto
import Authentication

extension AccessToken {
    /// access_token默认有效时间为一小时
    static let expirationInterval: TimeInterval = 3600
    
    typealias Token = String
}

struct AccessToken: MySQLModel {
    var id : Int?
    private(set) var token: Token
    private(set) var userId: Int
    let expiryTime: Date
    
    var createdAt: Date?
    var updatedAt: Date?
    var deletedAt: Date?
    
    static var createdAtKey: TimestampKey? { return \.createdAt }
    static var updatedAtKey: TimestampKey? { return \.updatedAt }
    static var deletedAtKey: TimestampKey? { return \.deletedAt }
    
    init(userId: Int) throws {
        self.token = try CryptoRandom().generateData(count: 32).base64EncodedString()
        self.userId = userId
        self.expiryTime = Date().addingTimeInterval(AccessToken.expirationInterval)
    }
}

extension AccessToken: Content {}
extension AccessToken: Migration {}

extension AccessToken: Authentication.Token {
    typealias UserType = User
    static var userIDKey: WritableKeyPath<AccessToken, Int> = \.userId
}

extension AccessToken: BearerAuthenticatable {
    static var tokenKey: WritableKeyPath<AccessToken, String> = \.token
    static func authenticate(using bearer: BearerAuthorization, on connection: DatabaseConnectable) -> Future<AccessToken?> {
        return Future.flatMap(on: connection) {
            return AccessToken.query(on: connection)
                .filter(tokenKey == bearer.token)
                .first()
                .map { token in
                    guard let token = token, token.expiryTime > Date() else {
                        return nil
                    }
                    
                    return token
            }
        }
    }
}























