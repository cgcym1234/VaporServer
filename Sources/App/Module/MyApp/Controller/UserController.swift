//
//  UserController.swift
//  App
//
//  Created by yangyuan on 2018/9/3.
//

import Vapor
import FluentSQL
import Crypto
import CNIOOpenSSL

final class UserController: RouteCollection {
    private let authService = AuthService()
    
    func boot(router: Router) throws {
        let group = router.grouped(Api.Path.Users.group)
        
        group.post(User.Register.self, at: Api.Path.Users.register, use: register)
        group.post(User.EmailLogin.self, at: Api.Path.Users.login, use: login)
        group.post(User.NewPassword.self, at: Api.Path.Users.newPassword, use: newPassword)
        
        /// 发送修改密码验证码
        group.post(User.Email.self, at: Api.Path.Users.changePasswordCode, use: changePasswordCode)
        
        /// 激活校验码
        group.get(Api.Path.Users.activateCode, use: activeRegisterEmailCode)
        
        /// 微信小程序
        /// /oauth/token 通过小程序提供的验证信息获取服务器自己的 token
        group.post(User.WXAppOAuth.self, at: Api.Path.Users.oauthToken, use: wxappOAuthToken)
    }
}

// MARK: - Handlers
private extension UserController {
    func register(_ req: Request, content: User.Register) throws -> Future<Response> {
        return UserAuth
            .query(on: req)
            .filter(\.identityType == .email)
            .filter(\.identifier == content.email)
            .first()
            .flatMap {
                if $0 != nil {
                    throw Api.Code.userExist.error
                }
                var userAuth = UserAuth(userId: nil, identityType: .email, identifier: content.email, credential: content.password)
                try userAuth.validate()
                let newUser = User(name: content.name, email: content.email, organizId: content.organizId)
                
                return newUser.create(on: req)
                    .flatMap { user in
                        userAuth.userId = try user.requireID()
                        return try userAuth
                            .auth(with: req.make(BCryptDigest.self))
                            .create(on: req)
                            .flatMap { _ in
                                return try self.sendRegisterEmail(on: req, user: user)
                            }
                            .flatMap { _ in
                                return try self.authService.token(for: userAuth.userId, on: req)
                        }
                }
        }
    }
    
    func login(_ req: Request, content: User.EmailLogin) throws -> Future<Response> {
        return UserAuth.query(on: req)
            .filter(\.identityType == .email)
            .filter(\.identifier == content.email)
            .first()
            .unwrap(or: Api.Code.userNotExist.error)
            .flatMap { authUser in
                let digest = try req.make(BCryptDigest.self)
                guard try digest.verify(content.password, created: authUser.credential) else {
                    throw Api.Code.authFail.error
                }
                
                return try self.authService.token(for: authUser.userId, on: req)
        }
    }
    
    func newPassword(_ req: Request, content: User.NewPassword) throws -> Future<Response> {
        return UserAuth.query(on: req)
            .filter(\.identityType == .email)
            .filter(\.identifier == content.email)
            .first()
            .unwrap(or: Api.Code.modelNotExist.error)
            .flatMap { userAuth in
                userAuth.user
                    .query(on: req)
                    .first()
                    .unwrap(or: Api.Code.modelNotExist.error)
                    .flatMap { user in
                        return try user.codes
                            .query(on: req)
                            .filter(\ActiveCode.codeType == ActiveCode.CodeType.changePassword.rawValue)
                            .filter(\ActiveCode.code == content.code)
                            .first()
                            .flatMap { code in
                                // 只有激活的用户才可以修改密码
                                guard let code = code, code.state else {
                                    throw Api.Code.codeFail.error
                                }
                                
                                var tmpUserAuth = userAuth
                                tmpUserAuth.credential = content.password
                                
                                return try tmpUserAuth.auth(with: req.make(BCryptDigest.self))
                                    .save(on: req)
                                    .map(to: Void.self) { _ in () }
                                    .toJson(on: req)
                        }
                }
        }
    }
    
    /// 发送修改密码的验证码
    func changePasswordCode(_ req: Request, content: User.Email) throws -> Future<Response> {
        return UserAuth.query(on: req)
            .filter(\.identityType == .email)
            .filter(\.identifier == content.email)
            .first()
            .unwrap(or: Api.Code.modelNotExist.error)
            .flatMap { auth in
                let codeStr = String.random(length: 4)
                let activeCode = ActiveCode(userId: auth.userId, code: codeStr, type: .changePassword)
                
                return try activeCode.create(on: req)
                    .flatMap { code in
                        try EmailManager.changePassword(email: content.email, code: codeStr).send(on: req)
                    }.toJson(on: req)
        }
    }
    
    /// 激活注册校验码
    func activeRegisterEmailCode(_ req: Request) throws -> Future<Response> {
        let model = try req.query.decode(User.RegisterCode.self)
        
        return ActiveCode.query(on: req)
            .filter(\.codeType == ActiveCode.CodeType.activeAccount.rawValue)
            .filter(\.userId == model.userId)
            .filter(\.code == model.code)
            .first()
            .unwrap(or: Api.Code.modelNotExist.error)
            .flatMap { code in
                code.state = true
                
                return try code.save(on: req)
                    .map(to: Void.self) { _ in }
                    .toJson(on: req)
        }
    }
    
    func wxappOAuthToken(_ req: Request, content: User.WXAppOAuth) throws -> Future<Response> {
        let appId = "wx295f34d030798e48"
        let secret = "39a549d066a34c56c8f1d34d606e3a95"
        let url = "https://api.weixin.qq.com/sns/jscode2session?appid=\(appId)&secret=\(secret)&js_code=\(content.code)&grant_type=authorization_code"
        return try req.make(Client.self)
        .get(url)
            .flatMap { res in
                guard let data = res.http.body.data else {
                    throw Api.Code.custom.error
                }
                
                let wxRes = try JSONDecoder.snakeCase.decode(User.WXAppResponse.self, from: data)
                
                guard
                    let sessionKey = wxRes.sessionKey.base64DecodedData(),
                let encryptedData = content.encryptedData.base64DecodedData(),
                    let iv = content.iv.base64DecodedData() else {
                        throw Api.Code.base64DecodeError.error
                }
                
                let cipher = CipherAlgorithm(c: OpaquePointer(EVP_aes_128_cbc()))
                let shiper = Cipher(algorithm: cipher)
                
                let decrypted = try shiper.decrypt(encryptedData, key: sessionKey, iv: iv)
                let wxUser = try JSONDecoder().decode(User.WXApp.self, from: decrypted)
                
                /// 通过 resContainer.session_key 和 data.openid
                if wxUser.watermark.appid == appId {
                    return UserAuth.query(on: req)
                    .filter(\.identityType == .wxapp)
                    .filter(\.identifier == wxUser.openId)
                    .first()
                        .flatMap {
                            if var userAuth = $0 {
                                let digest = try req.make(BCryptDigest.self)
                                userAuth.credential = try digest.hash(wxRes.sessionKey)
                                
                                return userAuth.update(on: req)
                                    .flatMap { _ in
                                        return try self.authService.token(for: userAuth.userId, on: req)
                                }
                            } else {
                                // 注册
                                var userAuth = UserAuth(userId: nil, identityType: .wxapp, identifier: wxUser.openId, credential: wxRes.sessionKey)
                                let newUser = User(name: wxUser.nickName, avator: wxUser.avatarUrl)
                                
                                return newUser.create(on: req)
                                    .flatMap { user in
                                        userAuth.userId = try user.requireID()
                                        
                                        return try userAuth.auth(with: req.make(BCryptDigest.self))
                                            .create(on: req)
                                            .flatMap { _ in
                                                return try self.authService.token(for: userAuth.userId, on: req)
                                        }
                                }
                            }
                    }
                } else {
                    throw Api.Code.custom.error
                }
        }
    }
}

private extension UserAuth {
    func auth(with digest: BCryptDigest) throws -> UserAuth {
        return try UserAuth(userId: userId, identityType: identityType, identifier: identifier, credential: digest.hash(credential))
    }
    
}








