//
//  MyFileManager.swift
//  App
//
//  Created by yuany on 2019/4/25.
//

import SwiftMarkdown

public final class MyFileMiddleware: Middleware, ServiceType {
    /// See `ServiceType`.
    public static func makeService(for container: Container) throws -> MyFileMiddleware {
        return try .init(publicDirectory: container.make(DirectoryConfig.self).workDir + "Public/")
    }
    
    /// The public directory.
    /// - note: Must end with a slash.
    private let publicDirectory: String
    
    /// Creates a new `FileMiddleware`.
    public init(publicDirectory: String) {
        self.publicDirectory = publicDirectory.hasSuffix("/") ? publicDirectory : publicDirectory + "/"
    }
    
    /// See `Middleware`.
    public func respond(to req: Request, chainingTo next: Responder) throws -> Future<Response> {
        // make a copy of the path
        var path = req.http.url.path
        
        // path must be relative.
        while path.hasPrefix("/") {
            path = String(path.dropFirst())
        }
        
        // protect against relative paths
        guard !path.contains("../") else {
            throw Abort(.forbidden)
        }
        
        // create absolute file path
        let filePath = publicDirectory + path
        
        // check if file exists and is not a directory
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: filePath, isDirectory: &isDir), !isDir.boolValue else {
            return try next.respond(to: req)
        }
        
        if path.pathExtension == "md" {
            return try req.fileio()
                .read(file: filePath)
                .map { String(data: $0, encoding: .utf8)! }
                .map { try markdownToHTML($0) }
                .map {
                    var http = HTTPResponse(status: .ok, body: $0)
                    http.contentType = Core.MediaType.html
                    return http
                }
                .map { Response(http: $0, using: req) }
        } else {
            // stream the file
            return try req.streamFile(at: filePath)
        }
    }
}
