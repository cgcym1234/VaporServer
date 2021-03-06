//
//  BlogController.swift
//  App
//
//  Created by yuany on 2019/4/26.
//

import Foundation

final class BlogController: RouteCollection {
    
    private var publicPath: String!
    
    func boot(router: Router) throws {
        router.get(Api.Path.Blog.group, use: publicBlogs)
    }
}

private extension BlogController {
    func blogs(in path: String) throws -> [Blog] {
        let folder = try YYFile.Folder(path: path)
        
        let files = folder.files.map {
            Blog(name: $0.name, isFolder: $0.kind == .folder, relativePath: $0.path.removingPrefix(publicPath))
        }
        
        let folders = folder.subfolders.map {
            Blog(name: $0.name, isFolder: $0.kind == .folder, relativePath: $0.path.removingPrefix(publicPath))
        }
        
        return files + folders
    }
    
    func publicBlogs(_ req: Request) throws -> Future<Response> {
        if publicPath == nil {
            publicPath = try req.make(DirectoryConfig.self).workDir + "Public/Blogs/"
        }
        
        var path = publicPath!
        if let subPath = try? req.query.get(String.self, at: "folder") {
            path += subPath
        }
        
        return try req.toJson(with: blogs(in: path))
    }
}
