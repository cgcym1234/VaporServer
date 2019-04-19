//
//  Api+Path.swift
//  App
//
//  Created by yuany on 2019/4/10.
//

import Foundation

extension Api {
    enum Path: String, PathComponentsRepresentable {
        case group = "api"
        
        case users
        case login
        case register
        case newPassword
        case changePasswordCode
        case activateCode
        case oauthToken = "oauth/token"
        
        case token
        case refresh
        case revoke
        
        
        var relativeValue: String {
            switch self {
            case .group:
                return rawValue
            default:
                return "\(type(of: self).group.rawValue)/\(rawValue)"
            }
        }
        
        var relativePath: String {
            return "/" + relativeValue
        }
        
        func convertToPathComponents() -> [PathComponent] {
            return [.init(stringLiteral: rawValue)]
        }
    }
    
}
