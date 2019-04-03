//
//  BoxueController.swift
//  App
//
//  Created by yuany on 2019/2/14.
//

import Vapor
import Fluent
import Crypto
import FluentMySQL

///`UserContext`表示要返回给App的信息，包括了当前登录用户（`username`），以及所有的论坛版块列表（`forums`）
struct UserContext: Codable, Content {
    var username: String?
    var forums: [Forum]
}

func getUsername(of: Request) -> String? {
    return "bx11"
}

struct MessageContext: Codable, Content {
    var username: String?
    var forum: Forum
    var message: [Message]
}

struct ReplyContext: Codable, Content {
    var username: String?
    var forum: Forum
    var message: Message
    var replies: [Message]
}

final class BoxueController: RouteCollection {
    func boot(router: Router) throws {
        router.get("forums") { req -> Future<Response> in
            return Forum.query(on: req).all()
                .map(to: UserContext.self) { UserContext(username: getUsername(of: req), forums: $0) }
                .encode(status: .ok, for: req)
        }
        
        router.group("users") { group in
            group.post("create") {
                req -> Future<Response> in
                var user = try req.content.syncDecode(Userb.self)
                
                return Userb.query(on: req)
                    .filter(\.email == user.email)
                    .first()
                    .flatMap(to: Response.self) { userExist in
                        guard userExist == nil else {
                            throw Abort(HTTPStatus.badRequest)
                        }
                        
                        user.password = try BCrypt.hash(user.password)
                        
                        return user.save(on: req).encode(status: .created, for: req)
                }
            }
            
            group.post(Userb.self, at: "login") { req, user -> Future<Response> in
                return Userb.query(on: req)
                    .filter(\.email == user.email)
                    .first()
                    .map { userExist -> Int in
                        guard userExist != nil else { throw Abort(.notFound) }
                        return 1
                    }.encode(status: .ok, for: req)
            }
        }
        
        router.group("forums", Int.parameter) { group in
            group.get("messages") { req -> Future<Response> in
                let forumId = try req.parameters.next(Int.self)
                
                return Forum.find(forumId, on: req)
                    .flatMap(to: Response.self) { forum in
                        guard let forum = forum else { throw Abort(.notFound) }
                        
                        return Message.query(on: req)
                            .filter(\.forumId == forum.id!)
                            .filter(\.originId == 0)
                            .all()
                            .map {
                                MessageContext(username: "bx11", forum: forum, message: $0)
                            }
                            .encode(status: .ok, for: req)
                }
            }
            
            /// GET /forums/{forumId}/messages/{messageId}
            /// 获取某个论坛中的某个帖子的所有回复
            group.get("messages", Int.parameter) { req -> Future<Response> in
                let fid = try req.parameters.next(Int.self)
                let mid = try req.parameters.next(Int.self)
                
                return Forum.find(fid, on: req)
                    .flatMap(to: Response.self, { forum in
                        guard let forum = forum else { throw Abort(.notFound) }
                        
                        return Message.find(mid, on: req)
                            .flatMap(to: Response.self, { message in
                                guard let message = message else { throw Abort(.notFound) }
                                
                                return Message.query(on: req)
                                    .filter(\.originId == message.id!)
                                    .all()
                                    .map {
                                        ReplyContext(username: "bx11", forum: forum, message: message, replies: $0)
                                    }
                                    .encode(status: .ok, for: req)
                            })
                    })
            }
        }
    }
}
