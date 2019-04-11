//
//  AuthService.swift
//  App
//
//  Created by yuany on 2019/4/10.
//

import Foundation
import FluentMySQL
import Crypto

extension AuthService {
    struct Public: Content {
        let accessToken: AccessToken.Token
        let expiresIn: TimeInterval
        let refreshToken: RefreshToken.Token
        
        init(accessToken: AccessToken, refreshToken: RefreshToken) {
            self.accessToken = accessToken.token
            self.expiresIn = accessToken.expiryTime.timeIntervalSince1970 //Not honored, just an estimate
            self.refreshToken = refreshToken.token
        }
    }
}

final class AuthService {
    func authentication(for refreshToken: RefreshToken.Token, on req: Request) throws -> Future<Response> {
        return try user(matching: refreshToken, on: req)
            .unwrap(or: Api.Code.userNotExist.error)
            .flatMap { user in
                try self.authentication(for: user.requireID(), on: req)
        }
    }
    
    func authentication(for userId: User.ID, on req: Request)
        throws -> Future<Response> {
            return try removeAllTokens(for: userId, on: req).flatMap { _ in
                try map(
                    to: Public.self,
                    self.accessToken(for: userId, on: req),
                    self.refreshToken(for: userId, on: req)
                ) { access, refresh in
                    return Public(accessToken: access, refreshToken: refresh)
                    }
                    .toJson(on: req)
            }
    }
    
    func revokeTokens(forEmail email: String, on conn: DatabaseConnectable)
        throws -> Future<Void> {
            return User
                .query(on: conn)
                .filter(\.email == email)
                .first()
                .flatMap { user in
                    guard let user = user else {
                        return Future.map(on: conn) { () }
                    }
                    
                    return try self.removeAllTokens(for: user.requireID(), on: conn)
            }
    }
}

// MARK: - User
private extension AuthService {
    func user(matching token: RefreshToken.Token, on conn: DatabaseConnectable)
        throws -> Future<User?> {
            return RefreshToken
                .query(on: conn)
                .filter(\RefreshToken.token == token)
                .first()
                .unwrap(or: Api.Error(code: .refreshTokenNotExist))
                .flatMap { token in
                    return User
                        .query(on: conn)
                        .filter(\.id == token.userId)
                        .first()
            }
    }
    
    func user(matching user: User, on conn: DatabaseConnectable)
        throws -> Future<User?> {
            return User
                .query(on: conn)
                .filter(\.email == user.email)
                .first()
    }
}

// MARK: - Token
private extension AuthService {
    func accessToken(for userId: User.ID, on conn: DatabaseConnectable)
        throws -> Future<AccessToken> {
            return try AccessToken(userId: userId).save(on: conn)
    }
    
    func refreshToken(for userId: User.ID, on conn: DatabaseConnectable)
        throws -> Future<RefreshToken> {
            return try RefreshToken(userId: userId).save(on: conn)
    }
    
    func accessToken(for refreshToken: RefreshToken, on conn: DatabaseConnectable)
        throws -> Future<AccessToken> {
            return try AccessToken(userId: refreshToken.userId).save(on: conn)
    }
    
    func removeAllTokens(for userId: User.ID?, on conn: DatabaseConnectable)
        throws -> Future<Void> {
            guard let userId = userId else {
                throw Api.Code.userNotExist.error
            }
            
            let accessTokens = AccessToken.query(on: conn)
                .filter(\.userId == userId)
                .delete()
            
            let refreshTokens = RefreshToken.query(on: conn)
                .filter(\.userId == userId)
                .delete()
            
            return map(to: Void.self, accessTokens, refreshTokens) { _,_ in
                ()
            }
    }
}


















