//
//  Api+Path.swift
//  App
//
//  Created by yuany on 2019/4/10.
//

import Foundation

extension Api {
    enum Path: String, PathComponentsRepresentable {
        case api
        case token
        case refresh
        case revoke
        case login
        case register
        case users
        case todos
        case search
        
        
        var relativeValue: String {
            switch self {
            case .api:
                return rawValue
            default:
                return "\(Path.api.rawValue)/\(rawValue)"
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
