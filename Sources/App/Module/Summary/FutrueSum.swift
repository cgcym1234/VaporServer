//
//  FutrueSum.swift
//  App
//
//  Created by yangyuan on 2019/1/31.
//

import Foundation

// MARK: - 引入Future的概念

///这种实现方式主要的一个问题就是在得到服务器的返回结果之后，如果我们要进一步执行一些异步操作，或者调用一些带有closure的方法，就会出现一层层closure嵌套的问题，而这种代码事后维护起来相当容易出错。
///为了解决这个问题，我们可以引入一个概念，即：某个来自未来的值。为此，在项目中新建一个future.swift，并在其中添加下面的代码：
class FutrueSum {
	enum Result<T> {
		case value(T)
		case error(Error)
	}
	
//	其中，ValueType就表示未来会得到的这个值的类型。对于当前的我们来说，Future描述的未来可能有三个状态：
//
//	- 根本就还不存在；
//	- 包含ValueType对象；
//	- 获取值的过程中发生了错误；
	class Futrue<ValueType> {
		///其中，后两种状态，我们可以用Result<ValueType>表示，而第一种状态，可以用nil表示，为此，我们给Future添加下面的代码：
		var result: Result<ValueType>? {
			///其次，当然就是关注result的值，当它发生变化的时候，我们就调用notify：
			didSet { result.map(notify) }
		}
		///这样，result就可以表示这个来自未来的值的结果了。
		
		///接下来，Future还应该保存一个通知列表，当result的值发生变化的时候，通知所有关心这个事情的人。为此，我们再给它添加一个callbacks属性：
		typealias Observer = (Result<ValueType>) -> Void
		lazy var callbacks = [Observer]()
		
		///其中的每一个Observer都表示一个关注result的对象。当然，我们还得给它添加一个“注册”新对象的方法：
		func register(with callback: @escaping Observer) {
			callbacks.append(callback)
			result.map(callback)
			///这里，为什么最后要调用result.map方法呢？这是因为，如果当前result中已经有了ValueType对象，我们可以立即把这个值通知到新加入的Observer。那么，这个通知的动作是如何实现的呢？
		}
		
		func notify(result: Result<ValueType>) {
			callbacks.forEach { $0(result) }
		}
		
		func map<NextValue>(_ closure: @escaping (ValueType) throws -> NextValue) rethrows -> Futrue<NextValue> {
			let promise = Promise<NextValue>()
			register { r in
				switch r {
				case .value(let value):
					do {
						let newValue = try closure(value)
						promise.resolve(with: newValue)
					}
					catch {
						promise.reject(with: error)
					}
				case .error(let error):
					promise.reject(with: error)
				}
			}
			
			return promise
		}
	}
}

// MARK: - 什么是Promise
///有了Future之后，我们来看与之搭配的另外一个概念：Promise。所谓promise，可以理解为承诺在未来得到了某个值之后，一定会做的事情。既然是在未来才会做的事情，我们可以把它定义成Future的派生类。继续在future.swift中，添加下面的代码：
extension FutrueSum {
	class Promise<ValueType>: Futrue<ValueType> {
		///resolve表示接受到成功值时的承诺，reject表示接受到失败值时的承诺
		func resolve(with value: ValueType) {
			result = .value(value)
		}
		
		func reject(with error: Error) {
			result = .error(error)
		}
		
		///于是，每当生成了一个Promise对象，就表示我们做出了一个承诺：在未来，当我们接受到成功值的时候要调用resolve，接受到错误值的时候要调用reject。值的注意的是，这并没有任何来自语言层次的约束，只是一个单纯的承诺罢了。
	}
}





















