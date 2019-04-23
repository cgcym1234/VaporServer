//
//  EmailManager.swift
//  App
//
//  Created by yuany on 2019/4/12.
//

import Foundation
import SwiftSMTP

extension EmailManager {
    func send(on req: Request) throws -> Future<Void> {
        let promise = req.eventLoop.newPromise(Void.self)
        let myEmail = "cgcym1234@163.com"
        
        let from = Mail.User(name: "yy", email: myEmail)
        let mail = Mail(from: from, to: [emailTo], subject: subject, text: text)
        
        let smtp = SMTP(hostname: "smtp.163.com", email: myEmail, password: "laozihs5dQQw", port: 465, tlsMode: .requireTLS, domainName: "book.twicebook.top")
        DispatchQueue.global().async {
            smtp.send(mail)
            promise.succeed()
        }
        
        return promise.futureResult
    }
}

enum EmailManager {
    case register(email: String, code: String)
    case accountActive(email: String, url: String)
    case changePassword(email: String, code: String)
    
    var emailTo: Mail.User {
        switch self {
        case let .register(email, _),
             let .accountActive(email, _),
             let .changePassword(email, _):
            
            return Mail.User(name: "EMgamean", email: email)
        }
    }
    
    var subject: String {
        switch self {
        case .register:
            return "注册验证码"
        case .changePassword:
            return "修改密码验证码"
        case .accountActive:
            return "激活账号"
        }
    }
    
    var text: String {
        switch self {
        case let .register(_, code):
            return "注册验证码是：\(code)"
        case let .changePassword(_, code):
            return "修改密码的验证码是: \(code)"
        case let .accountActive(_, url):
            return "点击此链接激活账号：\(url)"
        }
    }
}


