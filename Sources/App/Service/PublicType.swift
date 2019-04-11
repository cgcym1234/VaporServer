//
//  PublicType.swift
//  App
//
//  Created by yangyuan on 2018/9/3.
//

import Vapor


protocol PublicType {
	associatedtype Public: Content
	var `public`: Public { get }
}

extension Future where T: PublicType {
	var `public`: Future<T.Public> {
		return map(to: T.Public.self) { $0.public }
	}
}
