//
//  Api+Path.swift
//  App
//
//  Created by yuany on 2019/4/10.
//

import Foundation

// MARK: - Path
extension Api {
    enum Path: String, PathComponentsRepresentable {
        case group = "api"
        
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

// MARK: - Users
extension Api.Path {
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
                return Api.Path.group.relativeValue + "/" + rawValue
            default:
                return type(of: self).group.relativeValue + "/" + rawValue
            }
        }
        
        func convertToPathComponents() -> [PathComponent] {
            return [.init(stringLiteral: rawValue)]
        }
    }
}

// MARK: - Token
extension Api.Path {
    enum Token: String, PathComponentsRepresentable {
        case group = "token"
        case refresh
        case revoke
        
        var relativeValue: String {
            switch self {
            case .group:
                return Api.Path.group.relativeValue + "/" + rawValue
            default:
                return type(of: self).group.relativeValue + "/" + rawValue
            }
        }
        
        func convertToPathComponents() -> [PathComponent] {
            return [.init(stringLiteral: rawValue)]
        }
    }
}

// MARK: - Account
extension Api.Path {
    enum Account: String, PathComponentsRepresentable {
        case group = "account"
        case info
        case update
        
        var relativeValue: String {
            switch self {
            case .group:
                return Api.Path.group.relativeValue + "/" + rawValue
            default:
                return type(of: self).group.relativeValue + "/" + rawValue
            }
        }
        
        func convertToPathComponents() -> [PathComponent] {
            return [.init(stringLiteral: rawValue)]
        }
    }
}

// MARK: - Protected
extension Api.Path {
    enum Protected: String, PathComponentsRepresentable {
        case group = "protected"
        case basic
        case token
        
        var relativeValue: String {
            switch self {
            case .group:
                return Api.Path.group.relativeValue + "/" + rawValue
            default:
                return type(of: self).group.relativeValue + "/" + rawValue
            }
        }
        
        func convertToPathComponents() -> [PathComponent] {
            return [.init(stringLiteral: rawValue)]
        }
    }
}

// MARK: - Token
extension Api.Path {
    
}

// MARK: - Token
extension Api.Path {
    
}
