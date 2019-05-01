//
//  Validator.swift
//  App
//
//  Created by yuany on 2019/4/24.
//

import Validation


extension Validator where T == String {
    static var email: Validator<T> {
        return YYValidator.Email().validator()
    }
    
    static var password: Validator<T> {
        return YYValidator.Password().validator()
    }
}


public struct YYValidator {
    
}

// MARK: - Email
public extension YYValidator {
    struct Email: ValidatorType {
        
        public var validatorReadable: String {
            return "a valid email address"
        }
        
        public init() {}
        
        public func validate(_ s: String) throws {
            guard
                let range = s.range(of: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}", options: [.regularExpression, .caseInsensitive]),
                range.lowerBound == s.startIndex && range.upperBound == s.endIndex
                else {
                    throw Api.Code.emailInvalid.error
            }
        }
    }
}

// MARK: - Password
public extension YYValidator {
    struct Password: ValidatorType {
        private var ascii: Validator = .ascii
        private var length = Validator<String>.count(6...)
        private var number = Validator<String>.characterSet(.decimalDigits)
        private var lowercase = Validator<String>.characterSet(.lowercaseLetters)
        private var uppercase = Validator<String>.characterSet(.uppercaseLetters)
        
        public var validatorReadable: String {
            return "a valid password of 6 or more ASCII characters"
        }
        
        public func validate(_ data: String) throws {
            do {
                try ascii.validate(data)
                try length.validate(data)
                try number.validate(data)
                try lowercase.validate(data)
                try uppercase.validate(data)
            } catch {
                throw Api.Code.passwordInvalid.error
            }
        }
    }
}
