//
//  Public.swift
//  App
//
//  Created by yangyuan on 2018/9/3.
//

import Vapor


protocol PublicType {
	associatedtype T: Content
	var `public`: T { get }
}

extension Future where T: PublicType {
	var `public`: Future<T.T> {
		return map(to: T.T.self) { $0.public }
	}
}
