//
//  Summary.swift
//  App
//
//  Created by yangyuan on 2018/9/6.
//

import Foundation
import Vapor

///经过了解基础的概念后，可以再深一步来了解这些概念存在的意义和扩展的使用方法，包括Service、Client、Content、Session。
final class Summary {
	
	/*
	Service
	
	Service是一个依赖注入的框架，以可维护的方式来进行注册、配置和创建应用依赖。其实Vapor里的这个Service的概念有点像iOS里面组件化的解耦方案，使用路由或者协议建立起一个调度中心，去给有功能调用需求的地方分发服务。那应用到的组件就不会散落在项目的各处，同时可以针对自己需要的情景、功能来配置、选择对应的服务。
	*/
	///首先遵从一个空的协议Service（拿MyPrintLogger来举例）
	final class MyPrintLogger: Logger, Service {
		func log(_ string: String, at level: LogLevel, file: String, function: String, line: UInt, column: UInt) {
			
		}
	}
	
	///另外，遵从并实现ServiceType协议后可以更简单地注册服务
	final class MyPrintLogger2: ServiceType {
		static var serviceSupports: [Any.Type] {
			return  [Logger.self]
		}
		static func makeService(for worker: Container) throws -> MyPrintLogger2 {
			return MyPrintLogger2()
		}
	}
	
	func services(_ req: Request, _ services: inout Services, _ config: inout Config) throws {
		///然后在configure.swift将实现服务的类注册到Services结构体中，使用工厂方法动态地创建服务
		services.register(Logger.self) { container in
			return MyPrintLogger()
		}
		
		///遵从并实现ServiceType协议后可以更简单地注册服务
		services.register(MyPrintLogger2())
		///甚至可以指定注册的实例对象
		services.register(MyPrintLogger2(), as: Logger.self)
		///注意，如果使用引用类型（class）来注册服务的话，那么所有容器Container和子容器SubContainer都会共享这一个类型的这一个对象，同时要小心资源竞争的问题。
		
		/*
		配置服务
		
		如果同一个接口注册了多个服务，则需要指定优先的选择
		*/
		config.prefer(MyPrintLogger2.self, for: Logger.self)
		
		///当你注册过服务，那么就可以用容器Container来创建服务
		let logger = try req.make(Logger.self)
		print(type(of: logger)) // MyPrintLogger2
	}
	
	/*
	Provider
	
	通过Provider协议可以更简单地整合外部服务到当前应用。像所有的Vapor官方包都使用它来展示它们的服务。Provider可以用来注册到Services结构体中，可以勾进容器的生命周期。
	
	import Foo
	
	try services.register(FooProvider())
	*/
	final class MyLoggerProvider: Provider {
		func register(_ services: inout Services) throws {
			services.register(MyPrintLogger2.self)
		}
		
		func didBoot(_ container: Container) throws -> EventLoopFuture<Void> {
			let logger = try container.make(Logger.self)
			logger.debug("hello from MyPrintLogger")
			return .done(on: container)
		}
	}
	///实现Provider协议后，当注册LoggerProvider到应用的Services结构体中，它就会自动注册上面的两个服务。同时当容器启动的时候，就可以验证provider是否已经添加（注册服务）了。
	
	
	/*
	Client
	
	作为客户端使用时，首先需要一个服务容器（Container）来创建客户端。通常如果像进入你服务器的请求结果一样请求外部API，你就应该使用请求容器来创建一个客户端
	*/
	func client(_ req: Request, _ services: inout Services) throws {
		///只要容器（app、req）就能创建客户端
		let res = try req.client().get("http://vapor.codes")
		print(res) // Future<Response>
		
		///发送请求
		_ = try req.client().send(req)
	}
	
	
	/*
	Content
	
	有对应的编码器或解码器指定，模型才会按特定的序列形式在HTTP上进行通讯。
	
	因为所有的HTTP请求都必须包含content type，所以Vapor能根据这自动选择合适的编码器或者报错。同时也可以在应用的配置设定Vapor默认的编码器和解码器
	*/
	func content(services: inout Services) {
		/// Create default content config
		var contentConfig = ContentConfig.default()
		
		/// Create custom JSON encoder
		let jsonEncoder = JSONEncoder()
		jsonEncoder.dateEncodingStrategy = .millisecondsSince1970
		
		/// Register JSON encoder and content config
		contentConfig.use(encoder: jsonEncoder, for: .json)
		services.register(contentConfig)
	}
	
	/*
	便利解码
	
	为了更方便解码HTTP请求，Vapor提供了扩展的Router方法
	*/
	func reouter(router: Router) throws {
		///原始方法
		router.post("login") { (req) -> Future<HTTPStatus> in
			return try req.content.decode(User.self).map(to: HTTPStatus.self, { (user) in
				print(user.email)
				return .ok
			})
		}
		
		///效果同上的便利方法
		router.post(User.self, at: Path.login) { request, user -> HTTPStatus in
			print(user.email)
			return HTTPStatus.ok
		}
	}
	
	/*
	类型检测
	
	自定义解码器和编码器（默认情况下都是会使用JSON解码器或者编码器）
	*/
	func decoder(req: Request, res: Response, router: Router) throws {
		let user = try req.content.decode(User.self, using: JSONDecoder())
		print(user) // Future<User>
		
		try res.content.encode(user, as: .urlEncodedForm)
		
		///响应默认返回的是200 OK的状态码，也可以进行自定义
		//默认
		router.get("user") { req -> User in
			return User(name: "haha", email: "ddd", password: "ddd")
		}
		//自定义 created：201
		router.get("user") { req -> Future<Response> in
			return User(name: "haha", email: "ddd", password: "ddd").encode(status: .created, for: req)
		}
	}
	
	/*
	客户端
	
	客户端的HTTP编码就像服务端返回的HTTP响应编码一样。
	*/
	func clientDemo(req: Request) throws {
		///整个客户端的请求和接收响应的示例
		let login = User(name: "ddd", email: "dddd", password: "ddff")
		let user = try req.client().post("https://api.vapor.codes/login") { loginReq in
			/// Encode Content before Request is sent
			return try loginReq.content.encode(login)
			}.flatMap { loginRes in
				// Decode Content after Response is received
				return try loginRes.content.decode(User.self)
		}
		print(user)
	}
	
	/*
	Query String
	
	当明确请求使用的编码是URL-Encoded Form时，可以直接使用所有Request都包含有的QueryContainer来解码Query String，对编码也一样
	*/
	func queryString(req: Request) throws {
		let user = try req.query.decode(User.self)
		print(user)
		
		try req.query.encode(user)
		
		/*
		便利JSON
		
		由于有部分数据的编码没有规范标准，所以Vapor让自定义的JSON解码器更方便地处理这些数据
		*/
		/// Encode JSON using custom date encoding strategy
		try req.content.encode(json: user, using: .custom(dates: .millisecondsSince1970))
		
		// Decode JSON using custom date encoding strategy
		_ = try req.content.decode(json: User.self, using: .custom(dates: .millisecondsSince1970))
	}
	
	/*
	Session
	
	session 主要是维护客户端的连接状态，其通过为每个客户端创建唯一标识，并要求客户端在每一次请求中提供这个标识。这个标识可以利用任何的格式传递，但基本上都是使用cookies来完成。
	
	当一个新客户端的连接和session数据设置后，Vapor返回一个用于设置Cookieheader的值，然后客户端就会被要求在每次请求的Cookieheader上重复返回该值，所有浏览器都会自动完成这个流程。如果你想让session失效，Vapor就会删除相关的所有数据并通知客户端它们的cookie已经不再有效。
	*/
	func sessionDemo(_ req: Request, _ services: inout Services, router: Router) throws {
		///要实现session的功能，首先要将中间件MiddlewareConfig配置到全局
		
		var middlewares = MiddlewareConfig.default()
		middlewares.use(SessionsMiddleware.self)
		services.register(middlewares)
		
		///然后在每个路由中使用grouped(...)方法
		
		/// create a grouped router at /sessions w/ sessions enabled
		let sessions = router.grouped("sessions").grouped(SessionsMiddleware.self)
		/// create a route at GET /sessions/todos
		sessions.get(Path.todos) { req in
			///use session
			return ""
		}
		
		/*
		Vapor 默认下会将sessions保持在内存，也可以在配置中重写这个形式。还能使用Fluent的数据库或缓存来持久化sessions。
		
		当中间件生效后，就可以使用req.session()去访问
		*/
		
		// create a route at GET /sessions/get
		sessions.get("get") { req in
			// access "name" from session or return n/a
			return try req.session()["name"] ?? "n/a"
		}
		
		/// create a route at GET /sessions/set/:name
		sessions.get("set") { req -> String in
			/// get router param
			let name = try req.parameters.next(String.self)
			
			/// set name to session at key "name"
			try req.session()["name"] = name
			
			/// return the newly set name
			return name
		}
		
		/// create a route at GET /sessions/del
		sessions.get("del") { req -> String in
			// destroy the session
			try req.destroySession()
			
			// signal success
			return "done"
		}
	}
}























