//  Codable+YYLib.swift
//  SwiftProject
//
//  Created by yangyuan on 2018/6/6.
//  Copyright © 2018年 huan. All rights reserved.
//

import Foundation

// MARK: - 支持任何类型的Codable兼容序列化机制
public protocol AnyDecoder {
	func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}
extension JSONDecoder: AnyDecoder {}
extension PropertyListDecoder: AnyDecoder {}

public extension Data {
	/// let user = try data.decoded() as User
    func decoded<T: Decodable>(using decoder: AnyDecoder = JSONDecoder.snakeCase) throws -> T {
		return try decoder.decode(T.self, from: self)
	}
}

// MARK: - AnyEncoder
public protocol AnyEncoder {
	func encode<T: Encodable>(_ value: T) throws -> Data
}
extension JSONEncoder: AnyEncoder {}
extension PropertyListEncoder: AnyEncoder {}

public extension Encodable {
	/// let data = try user.encoded()
	func encoded(using encoder: AnyEncoder = JSONEncoder.snakeCase) throws -> Data {
		return try encoder.encode(self)
	}
}

public extension JSONDecoder {
    static let snakeCase: JSONDecoder = {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		return decoder
	}()
}

public extension JSONEncoder {
    static let snakeCase: JSONEncoder = {
		let decoder = JSONEncoder()
		decoder.keyEncodingStrategy = .convertToSnakeCase
		return decoder
	}()
}

// MARK: - 消除解码时的冗长和类型
//init(from decoder: Decoder) throws {
//	let container = try decoder.container(keyedBy: CodingKey.self)
//	url = try container.decode(forKey: .url)
//	containsAds = try container.decode(forKey: .containsAds, default: false)
//	comments = try container.decode(forKey: .comments, default: [])
//}
public extension KeyedDecodingContainerProtocol {
    func decode<T: Decodable>(forKey key: Key) throws -> T {
		return try decode(T.self, forKey: key)
	}
	
    func decode<T: Decodable>(forKey key: Key,
							  default defaultExpresion: @autoclosure () -> T
		) throws -> T {
		return try decodeIfPresent(T.self, forKey: key) ?? defaultExpresion()
	}
}

//// MARK: - 忽略`DecodingError.keyNotFound`异常信息,当key不存在时返回`nil`
//public extension KeyedDecodingContainer {
//
//	public func decode(_ type: Bool.Type, forKey key: KeyedDecodingContainer.Key) throws -> Bool {
//		return try decodeIfPresent(type, forKey: key) ?? false
//	}
//
//	public func decode(_ type: String.Type, forKey key: KeyedDecodingContainer.Key) throws -> String {
//		return try decodeIfPresent(type, forKey: key) ?? ""
//	}
//
//	public func decode(_ type: Double.Type, forKey key: KeyedDecodingContainer.Key) throws -> Double {
//		return try decodeIfPresent(type, forKey: key) ?? 0.0
//	}
//
//	public func decode(_ type: Float.Type, forKey key: KeyedDecodingContainer.Key) throws -> Float {
//		return try decodeIfPresent(type, forKey: key) ?? 0.0
//	}
//
//	public func decode(_ type: Int.Type, forKey key: KeyedDecodingContainer.Key) throws -> Int {
//		return try decodeIfPresent(type, forKey: key) ?? 0
//	}
//
//	public func decode(_ type: UInt.Type, forKey key: KeyedDecodingContainer.Key) throws -> UInt {
//		return try decodeIfPresent(type, forKey: key) ?? 0
//	}
//
//	public func decode<T>(_ type: T.Type, forKey key: KeyedDecodingContainer.Key) throws -> T where T : Decodable {
//
//		if let value = try decodeIfPresent(type, forKey: key) {
//			return value
//		} else if let objectValue = try? JSONDecoder().decode(type, from: "{}".data(using: .utf8)!) {
//			return objectValue
//		} else if let arrayValue = try? JSONDecoder().decode(type, from: "[]".data(using: .utf8)!) {
//			return arrayValue
//		} else if let stringValue = try decode(String.self, forKey: key) as? T {
//			return stringValue
//		} else if let boolValue = try decode(Bool.self, forKey: key) as? T {
//			return boolValue
//		} else if let intValue = try decode(Int.self, forKey: key) as? T {
//			return intValue
//		} else if let uintValue = try decode(UInt.self, forKey: key) as? T {
//			return uintValue
//		} else if let doubleValue = try decode(Double.self, forKey: key) as? T {
//			return doubleValue
//		} else if let floatValue = try decode(Float.self, forKey: key) as? T {
//			return floatValue
//		}
//		let context = DecodingError.Context(codingPath: [key], debugDescription: "Key: <\(key.stringValue)> cannot be decoded")
//		throw DecodingError.dataCorrupted(context)
//	}
//
//	public func decodeIfPresent(_ type: Bool.Type, forKey key: K) throws -> Bool? {
//
//		guard contains(key) else { return nil }
//
//		let decoder = try superDecoder(forKey: key)
//		let container = try decoder.singleValueContainer()
//
//		if let value = try? container.decode(type) {
//			return value
//		} else if let intValue = try? container.decode(Int.self) {
//			return intValue == 0 ? false : true
//		} else if let stringValue = try? container.decode(String.self) {
//			return stringValue.toBool()
//		}
//
//		return nil
//	}
//
//	public func decodeIfPresent(_ type: String.Type, forKey key: K) throws -> String? {
//
//		guard contains(key) else { return nil }
//
//		let decoder = try superDecoder(forKey: key)
//		let container = try decoder.singleValueContainer()
//
//		if let value = try? container.decode(type) {
//			return value
//		} else if let intValue = try? container.decode(Int.self) {
//			return String(intValue)
//		} else if let doubleValue = try? container.decode(Double.self) {
//			return String(doubleValue)
//		} else if let boolValue = try? container.decode(Bool.self) {
//			return String(boolValue)
//		}
//		return nil
//	}
//
//	public func decodeIfPresent(_ type: Double.Type, forKey key: K) throws -> Double? {
//
//		guard contains(key) else { return nil }
//
//		let decoder = try superDecoder(forKey: key)
//		let container = try decoder.singleValueContainer()
//
//		if let value = try? container.decode(type) {
//			return value
//		} else if let stringValue = try? container.decode(String.self) {
//			return Double(stringValue)
//		}
//		return nil
//	}
//
//	public func decodeIfPresent(_ type: Float.Type, forKey key: K) throws -> Float? {
//
//		guard contains(key) else { return nil }
//
//		let decoder = try superDecoder(forKey: key)
//		let container = try decoder.singleValueContainer()
//
//		if let value = try? container.decode(type) {
//			return value
//		} else if let stringValue = try? container.decode(String.self) {
//			return Float(stringValue)
//		}
//		return nil
//	}
//
//	public func decodeIfPresent(_ type: Int.Type, forKey key: K) throws -> Int? {
//
//		guard contains(key) else { return nil }
//
//		let decoder = try superDecoder(forKey: key)
//		let container = try decoder.singleValueContainer()
//
//		if let value = try? container.decode(type) {
//			return value
//		} else if let stringValue = try? container.decode(String.self) {
//			return Int(stringValue)
//		}
//		return nil
//	}
//
//	public func decodeIfPresent(_ type: UInt.Type, forKey key: K) throws -> UInt? {
//
//		guard contains(key) else { return nil }
//
//		let decoder = try superDecoder(forKey: key)
//		let container = try decoder.singleValueContainer()
//
//		if let value = try? container.decode(type) {
//			return value
//		} else if let stringValue = try? container.decode(String.self) {
//			return UInt(stringValue)
//		}
//		return nil
//	}
//
//	public func decodeIfPresent<T>(_ type: T.Type, forKey key: K) throws -> T? where T : Decodable {
//
//		guard contains(key) else { return nil }
//
//		let decoder = try superDecoder(forKey: key)
//		let container = try decoder.singleValueContainer()
//		return try? container.decode(type)
//	}
//}
