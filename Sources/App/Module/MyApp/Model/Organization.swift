//
//  Organization.swift
//  App
//
//  Created by yuany on 2019/4/10.
//

import Foundation
import FluentMySQL

/// 组织表
final class Organization: MySQLModel {
    var id: Int?
    var parentId: Organization.ID
    var name: String
    var remarks: String?
    
    var createdAt: Date?
    var updatedAt: Date?
    var deletedAt: Date?
    
    static var createdAtKey: TimestampKey? { return \.createdAt }
    static var updatedAtKey: TimestampKey? { return \.updatedAt }
    static var deletedAtKey: TimestampKey? { return \.deletedAt }
    
    init(parentId: Organization.ID, name: String, remarks: String?) {
        self.parentId = parentId
        self.name = name
        self.remarks = remarks
    }
}

extension Organization {
    var users: Children<Organization, User> {
        return children(\User.organizId)
    }
}

extension Organization: Content {}
extension Organization: Migration {}

extension Organization {
    struct Forms: Migration {
        typealias Database = MySQLDatabase
        
        static let organizations = [
            "再书"
        ]
        
        static func prepare(on conn: MySQLConnection) -> EventLoopFuture<Void> {
            return organizations
                .map { Organization(parentId: 0, name: $0, remarks: $0) }
                .map { $0.create(on: conn) }
                .flatten(on: conn)
                .transform(to: ())
        }
        
        static func revert(on conn: MySQLConnection) -> EventLoopFuture<Void> {
            return organizations
                .map {
                    Organization.query(on: conn)
                        .filter(\.name == $0).delete()
                }
                .flatten(on: conn)
                .transform(to: ())
            //            let futures = organizations.map {
            //                Organization.query(on: conn)
            //                    .filter(\.name == $0).delete()
            //            }.flatten(on: conn).transform(to: ())
            //
            //            return Future<Void>.andAll(futures, eventLoop: conn.eventLoop)
        }
    }
}
