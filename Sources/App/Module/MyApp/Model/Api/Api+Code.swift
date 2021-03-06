//
//  Api+Code.swift
//  App
//
//  Created by yuany on 2019/4/10.
//

import Foundation

extension Api.Code {
    var error: Api.Error {
        return Api.Error(code: self)
    }
}

extension Api {
    enum Code: Int, Content {
        case ok = 0  // 请求成功状态
        
        /// 接口失败
        case userExist = 1000
        case userNotExist = 1001
        case passwordInvalid = 1002
        case passwordError = 1003
        case emailInvalid = 1008
        case emailNotExist = 1009
        
        case bookNotExist = 24
        case modelNotExist = 25
        case modelExisted = 26
        case authFail = 27
        case codeFail = 28
        case resonNotExist = 29
        case base64DecodeError = 30
        
        case custom = 31
        case refreshTokenNotExist = 32
        
        var desc: String {
            switch self {
            case .ok:
                return "请求成功"
            case .userExist:
                return "用户已经存在"
            case .userNotExist:
                return "用户不存在"
            case .passwordInvalid:
                return "密码不合法"
            case .passwordError:
                return "密码错误"
            case .emailNotExist:
                return "邮箱不存在"
            case .emailInvalid:
                return "邮箱不合法"
            case .bookNotExist:
                return "书籍不存在"
            case .modelNotExist:
                return "对象不存在"
            case .modelExisted:
                return "对象已存在"
            case .authFail:
                return "密码错误"
            case .codeFail:
                return "验证码错误"
            case .resonNotExist:
                return "不存在reason"
            case .base64DecodeError:
                return "base64 decode 失败"
            case .custom:
                return "出错了"
            case .refreshTokenNotExist:
                return "refreshToken 不存在"
            }
        }
    }
}
