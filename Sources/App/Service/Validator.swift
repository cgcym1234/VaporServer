//
//  Validator.swift
//  App
//
//  Created by yuany on 2019/4/24.
//

import Validation


extension Validator where T == String {
    static var password: Validator<T> {
        return PasswordValidator().validator()
    }
}

struct PasswordValidator: ValidatorType {
    private var ascii: Validator = .ascii
    private var length = Validator<String>.count(6...)
    private var number = Validator<String>.characterSet(.decimalDigits)
    private var lowercase = Validator<String>.characterSet(.lowercaseLetters)
    private var uppercase = Validator<String>.characterSet(.uppercaseLetters)
    
    var validatorReadable: String {
        return "a valid password of 6 or more ASCII characters"
    }
    
    func validate(_ data: String) throws {
        try ascii.validate(data)
        try length.validate(data)
        try number.validate(data)
        try lowercase.validate(data)
        try uppercase.validate(data)
    }
}
