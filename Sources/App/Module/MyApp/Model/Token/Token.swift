//
//  Token.swift
//  App
//
//  Created by yangyuan on 2018/9/3.
//

import Authentication
import FluentSQLite
import Vapor

struct Token: Content {
    let accessToken: AccessToken.Token
    let expiresIn: TimeInterval
    let refreshToken: RefreshToken.Token
    
    init(accessToken: AccessToken, refreshToken: RefreshToken) {
        self.accessToken = accessToken.token
        self.expiresIn = accessToken.expiryTime.timeIntervalSince1970 //Not honored, just an estimate
        self.refreshToken = refreshToken.token
    }
}
