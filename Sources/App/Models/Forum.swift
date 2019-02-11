//
//  Forum.swift
//  App
//
//  Created by yangyuan on 2019/2/2.
//

import Vapor
import Fluent
import Foundation
import FluentMySQL

struct Forum: Content, MySQLModel, Migration {
	var id: Int?
	var name: String
}

