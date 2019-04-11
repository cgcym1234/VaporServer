//
//  Boxue.swift
//  App
//
//  Created by yuany on 2019/2/14.
//

import Vapor
import Fluent
import Foundation
import FluentMySQL

struct Forum: Content, MySQLModel {
    var id: Int?
    var name: String
    
    init(id: Int?, name: String) {
        self.id = id
        self.name = name
    }
    
    init(name: String) {
        self.init(id: nil, name: name)
    }
}

extension Forum: Migration {
    //    //默认实现
    //    static func prepare(on connection: MySQLConnection) -> Future<Void> {
    //        return Database.create(Forum.self, on: connection) {
    //            builder in
    //            try addProperties(to: builder)
    //        }
    //    }
    //
    //    static func revert(on connection: MySQLConnection) -> Future<Void> {
    //        return Database.delete(Forum.self, on: connection)
    //    }
}

extension Forum {
    struct Seeder: Migration {
        typealias Database = MySQLDatabase
        
        static func prepare(on conn: Database.Connection) -> Future<Void> {
            return [1, 2, 3]
                .map { i in
                    Forum(name: "Forum \(i)")
                }
                .map { $0.save(on: conn) }
                .flatten(on: conn)
                .transform(to: ())
        }
        
        static func revert(on conn: Database.Connection) -> Future<Void> {
            return conn.query("truncate table `Forum`").transform(to: ())
        }
    }
    
}



struct Message: Content, MySQLModel {
    var id: Int?
    var forumId: Int
    var title: String
    var content: String
    var originId: Int
    var author: String
    var createdAt: Date
}

extension Message: Migration {
}

extension Message {
    struct Seeder: Migration {
        typealias Database = MySQLDatabase
        
        static func prepare(on connection: Database.Connection) -> Future<Void> {
            var messageId = 0
            
            return 3.toArray().flatMap {
                forum in
                return 5.toArray().map {
                    message -> Message in
                    messageId += 1
                    let title = "Title \(message) in Forum \(forum)"
                    let content = "Body of Title \(message)"
                    let originId = message > 3 ? (forum * 5 - 4) : 0
                    return Message(
                        id: messageId,
                        forumId: forum,
                        title: title,
                        content: content,
                        originId: originId,
                        author: "bx11",
                        createdAt: Date())
                }
                }
                .map { $0.create(on: connection) }
                .flatten(on: connection)
                .transform(to: ())
        }
        
        static func revert(on conn: Database.Connection) -> Future<Void> {
            return conn.query("truncate table `Message`").transform(to: ())
        }
    }
}



struct Userb: Content, MySQLModel {
    var id: Int?
    var email: String
    var password: String
}

extension Userb: Migration { }

