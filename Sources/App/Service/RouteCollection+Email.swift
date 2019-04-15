//
//  RouteCollection+Email.swift
//  App
//
//  Created by yuany on 2019/4/12.
//

import Vapor
import Crypto

extension RouteCollection {
    func sendRegisterEmail(on req: Request, user: User) throws -> Future<Void> {
        let userId = try user.requireID()
        let codeStr = try MD5.hash(Data(Date().description.utf8)).hexEncodedString().lowercased()
        let code = ActiveCode(userId: userId, code: codeStr, type: .activeAccount)
        return code.save(on: req)
            .flatMap { code in
                let scheme = req.http.headers.firstValue(name: .host) ?? ""
                let link = "https://\(scheme)/api/users/activate?userId=\(userId)&code=\(code.code)"
                guard let email = user.email else {
                    throw Api.Code.emailNotExist.error
                }
                
                return try EmailManager.accountActive(email: email, url: link).send(on: req)
        }
    }
}
