//
//  path.swift
//  App
//
//  Created by yangyuan on 2018/9/3.
//

import Vapor

enum Path: String {
	case api
	case auth
	case login
	case register
	case users
	case todos
	case search
}

extension Path: PathComponentsRepresentable {
	func convertToPathComponents() -> [PathComponent] {
		return [.init(stringLiteral: self.rawValue)]
	}
}

