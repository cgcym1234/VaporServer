//
//  Api+Error.swift
//  App
//
//  Created by yuany on 2019/4/10.
//

import Foundation

extension Api {
    struct Error: Content {
        var message: String
        var code: Code
        
        init(code: Code, message: String? = nil) {
            self.message = message ?? code.desc
            self.code = code
        }
    }
}

extension Api.Error: AbortError {
    var identifier: String {
        return message
    }
    
    var reason: String {
        return message
    }
    
    var status: HTTPResponseStatus {
        return .ok
    }
}
