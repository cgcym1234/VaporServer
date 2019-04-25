//
//  Api+Response.swift
//  App
//
//  Created by yuany on 2019/4/11.
//

import Foundation

struct Empty: Content {}

extension Api {
    static var emptyResponse: Response<Empty> {
        return Response<Empty>()
    }
    
    struct Response<T: Content>: Content {
        private var status: Code
        private var message: String
        private var data: T?
        
        init(data: T? = nil) {
            status = .ok
            message = status.desc
            self.data = data
        }
        
        static func success(_ data: T) -> Response<T> {
            return Response(data: data)
        }
    }
}


extension Future where T: Content {
    func toJson(on request: Request) throws -> Future<Response> {
        return try map { data in
            Api.Response(data: data)
        }.encode(for: request)
    }
}

extension Future where T == Void {
    func toJson(on request: Request) throws -> Future<Response> {
        return try self.transform(to: Api.emptyResponse)
            .encode(for: request)
    }
}

extension Request {
    func toJson() throws -> Future<Response> {
        return try Api.emptyResponse.encode(for: self)
    }
    
    func toJson<T: Content>(with content: T) throws -> Future<Response> {
        return try Api.Response(data: content).encode(for: self)
    }
}
