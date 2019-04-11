//
//  Api+Error.swift
//  App
//
//  Created by yuany on 2019/4/10.
//

import Foundation

extension Api {
    struct Error: Debuggable, Content {
        var identifier: String
        var reason: String
        var code: Code
        
        init(code: Code, message: String? = nil) {
            self.identifier = "api error: \(code.rawValue)"
            self.reason = message ?? code.desc
            self.code = code
        }
    }
}

extension Api.Error: AbortError {
    var status: HTTPResponseStatus {
        return .ok
    }
}
