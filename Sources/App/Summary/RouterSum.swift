//
//  RouterSum.swift
//  App
//
//  Created by yangyuan on 2019/2/1.
//

import Vapor

// MARK: - 使用group组织路由

//这一节，我们来看在Vapor中批量组织路由的方法。为什么需要批量组织路由呢？一个典型的场景，就是为HTTP API，提供统一的名字空间。例如，我们有下面两个API：
//- GET /v1/episodes：表示获取所有视频；
//- GET /v1/users：表示获取所有用户；
class RouterSum {
	func routes1(_ router: Router) throws {
		///Vapor提供了group方法：
		router.group("v1") { group in
			group.get("episodes") { req -> String in
				return "Episode list"
			}
			
			group.get("episodes") { req -> String in
				return "User list"
			}
		}
		
		///给group添加参数
//		但有时，我们添加到名字空间中的路由，有可能是动态的，例如，下面这两个HTTP API：
//
//		- POST /v1/episodes/1/play：表示播放id为1的视频；
//		- POST /v1/episodes/1/finish：表示把id为1的视频标记为已完成；
		router.group("v1") {
			group in
			group.group("episodes", Int.parameter) {
				subgroup in
				subgroup.post("play") {
					req -> String in
					let id = try req.parameters.next(Int.self)
					return "Play episode \(id)"
				}
				
				subgroup.post("finish") {
					req -> String in
					let id = try req.parameters.next(Int.self)
					return "Finish episode \(id)"
				}
			}
		}
		
//		把group作为单独对象使用
//
//		上面这种嵌套路由的方式有一个缺陷，就是当一个名字空间里的路由较多时，group的closure就会很长，不方便维护。为此，我们可以把route group单独定义成对象：
		router.group("v1") { group in
			let subgroup = group.grouped("episodes", Int.parameter)
			subgroup.post("play") { req -> String in
				let id = try req.parameters.next(Int.self)
				return "Play episode \(id)"
			}
			
			subgroup.post("finish") {
				req -> String in
				let id = try req.parameters.next(Int.self)
				return "Finish episode \(id)"
			}
		}
	}
}

// MARK: - 自定义route collection组织路由
///除了把路由统一定义在routes方法中之外，如果路由比较复杂，我们还可以按功能把它们定义在单独的文件里，然后统一“注册”到router。这一节，我们就来分享这个方法。
extension RouterSum: RouteCollection {
	///可以看到，boot只接受一个Router参数，我们可以把它就当成之前在routes方法中使用的router。因此，在这里定义路由的方法，和之前是完全一样的。我可以单独定义路由，可以用group，也可以用grouped。
	func boot(router: Router) throws {
		let group = router.grouped("episode", Int.parameter)
		
		group.get("play") { req -> HTTPStatus in
			let id = try req.parameters.next(Int.self)
			print(id)
			return .noContent
		}
		
		group.post("finish") { req -> HTTPStatus in
			return .noContent
		}
	}
	
	// MARK: - 注册route collection
	///定义好RouteCollection之后，为了可以让Vapor在启动的时候加载它，我们需要在之前使用的routes方法中注册一下：
	public func routes(_ router: Router) throws {
		try router.register(collection: RouterSum())
	}
}








