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
        
        enum Users: String, PathComponentsRepresentable {
            case group = "users"
            case login
            case register
            case info
            case newPassword
            case changePasswordCode
            case activateCode
            case oauthToken = "oauth/token"
            
            var relativeValue: String {
                switch self {
                case .group:
                    return Path.group.relativeValue + "/" + rawValue
                default:
                    return type(of: self).group.relativeValue + "/" + rawValue
                }
            }
            
            func convertToPathComponents() -> [PathComponent] {
                return [.init(stringLiteral: rawValue)]
            }
        }
        
        enum Token: String, PathComponentsRepresentable {
            case group = "token"
            case refresh
            case revoke
            
            var relativeValue: String {
                switch self {
                case .group:
                    return Path.group.relativeValue + "/" + rawValue
                default:
                    return type(of: self).group.relativeValue + "/" + rawValue
                }
            }
            
            func convertToPathComponents() -> [PathComponent] {
                return [.init(stringLiteral: rawValue)]
            }
        }
        
        enum Account: String, PathComponentsRepresentable {
            case group = "account"
            case info
            case update
            
            var relativeValue: String {
                switch self {
                case .group:
                    return Path.group.relativeValue + "/" + rawValue
                default:
                    return type(of: self).group.relativeValue + "/" + rawValue
                }
            }
            
            func convertToPathComponents() -> [PathComponent] {
                return [.init(stringLiteral: rawValue)]
            }
        }
        
        var relativeValue: String {
            switch self {
            case .group:
                return rawValue
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

