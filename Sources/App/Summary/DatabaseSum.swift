//
//  DatabaseSum.swift
//  App
//
//  Created by yangyuan on 2018/9/8.
//

import Foundation
import Vapor
import FluentSQLite
import DatabaseKit

/*
数据库选型

MySQL 和 PostgreSQL 的对比，网上已经很多分析，例如这篇PostgreSQL 与 MySQL 相比，优势何在？。为了感受一下潮流，我选择了PostgreSQL来学习和练习。

DatabaseKit

Connection

DatabaseKit主要负责创建、管理和合并连接。有了连接我们才能访问数据库，而创建连接对应用来说是一件非常耗时的任务，以至于很多云服务都会限制一个服务能打开的连接数，关于性能方面的知识可以自行去了解。参考1参考2

由路由传入request来请求连接时，如果连接池中没有可用的连接则创建一条新连接，若连接数达到了上限则等待被释放放回的连接。

再观察一下Request实现的协议

public final class Request: ContainerAlias, DatabaseConnectable, HTTPMessageContainer, RequestCodable, CustomStringConvertible, CustomDebugStringConvertible

其中就是DatabaseConnectable决定Request拥有连接数据库的能力
*/
final class DatabaseSum {
	func req(req: Request, service: inout Services, app: Application) {
		// 请求一条连接池中的连接，连到 `.psql` db
//		req.withPooledConnection(to: .psql) { conn in
//			return conn.query(...) // do some db query
//		}
//		如果你想手动请求一条连接，就要对应地手动释放此条连接
//		req.requestPooledConnection(to: .psql).wait()
		
		///可以配置连接数据库的连接池
		let pool = DatabaseConnectionPoolConfig(maxConnections: 8)
		service.register(pool)
		
		/*
		为了避免竞争的状况出现，连接池绝对不能在事件循环之间共享使用。通常一个连接池对应一个数据库和一个事件循环。意味着应用打开指定数据库的连接数为 线程数 * 池中的最大连接数。
		
		还可以单独地创建连接，但必须注意的是，不要在路由的回调闭包中这样使用，因为频繁的访问会导致创建出很多连接，而由路由回调闭包返回的连接则是从连接池中获取的。
		*/
//		app.withNewConnection(to: .sqlite) { conn in
//			
//		}
	}
}

