//
//  YYFile+Foundation.swift
//  SwiftProject
//
//  Created by yangyuan on 2018/11/29.
//  Copyright © 2018 huan. All rights reserved.
//

import Foundation

/// Protocol adopted by file system types that may be iterated over (this protocol is an implementation detail)
public protocol YYFileIterable {
	/// Initialize an instance with a path and a file manager
	init(path: String, using fileManager: FileManager) throws
}

extension YYFile {
	public enum Kind: CustomStringConvertible {
		case file
		case folder
		
		public var description: String {
			switch self {
			case .file:
				return "File"
			case .folder:
				return "Folder"
			}
		}
	}
}



extension YYFile {
	public enum PathError: Error, Equatable, CustomStringConvertible {
		case empty
		/// 在找不到给定路径的预期类型的项目时抛出（包含路径）
		case invalid(String)
		
		/// Operator used to compare two instances for equality
		public static func ==(lhs: PathError, rhs: PathError) -> Bool {
			switch (lhs, rhs) {
			case (.empty, .empty):
				return true
			case (.invalid(let path1), .invalid(let path2)):
				return path1 == path2
			default:
				return false
			}
		}
		
		/// A string describing the error
		public var description: String {
			switch self {
			case .empty:
				return "Empty path given"
			case .invalid(let path):
				return "Invalid path given: \(path)"
			}
		}
	}
}

extension YYFile {
	public enum OperationError: Error, Equatable, CustomStringConvertible {
		case rename(Item)
		case move(Item)
		case copy(Item)
		case delete(Item)
		
		/// Operator used to compare two instances for equality
		public static func ==(lhs: OperationError, rhs: OperationError) -> Bool {
			switch (lhs, rhs) {
			case (.rename(let obj1), .rename(let obj2)):
				return obj1 == obj2
			case (.move(let obj1), .move(let obj2)):
				return obj1 == obj2
			case (.copy(let obj1), .copy(let obj2)):
				return obj1 == obj2
			case (.delete(let obj1), .delete(let obj2)):
				return obj1 == obj2
			default:
				return false
			}
		}
		
		/// A string describing the error
		public var description: String {
			switch self {
			case .rename(let item):
				return "Failed to rename item: \(item)"
			case .move(let item):
				return "Failed to move item: \(item)"
			case .copy(let item):
				return "Failed to copy item: \(item)"
			case .delete(let item):
				return "Failed to delete item: \(item)"
			}
		}
	}
}



public extension ProcessInfo {
    var homeFolderPath: String {
		return environment["HOME"]!
	}
}

public extension FileManager {
    func itemKind(atPath path: String) -> YYFile.Kind? {
		var isFolder: ObjCBool = false
		guard fileExists(atPath: path, isDirectory: &isFolder) else {
			return nil
		}
		
		return isFolder.boolValue ? .folder : .file
	}
	
    func itemNames(inFolderAtPath path: String) -> [String] {
		do {
			return try contentsOfDirectory(atPath: path).sorted()
		} catch {
			return []
		}
	}
	
    func parentPath(for path: String) -> String? {
		guard path != "/" else {
			return nil
		}
		
		var pathComponents = path.pathComponents
		
		if path.hasSuffix("/") {
			pathComponents.removeLast(2)
		} else {
			pathComponents.removeLast()
		}
		
		return pathComponents.joined(separator: "/")
	}
	
    func absolutePath(for path: String) throws -> String {
		if path.hasPrefix("/") {
			return try pathByFillingParent(for: path)
		}
		
		if path.hasSuffix("~") {
			let prefixEndIndex = path.index(after: path.startIndex)
			
			let path = path.replacingCharacters(in: path.startIndex..<prefixEndIndex, with: ProcessInfo.processInfo.homeFolderPath)
			
			return try pathByFillingParent(for: path)
		}
		
		return try pathByFillingParent(for: path, prependCurrentFolderPath: true)
	}
	
    func pathByFillingParent(for path: String, prependCurrentFolderPath: Bool = false) throws -> String {
		var path = path
		var filledIn = false
		
		while let parentReferenceRange = path.range(of: "../") {
			let currentFolderPath = String(path[..<parentReferenceRange.lowerBound])
			guard let currentFolder = try? YYFile.Folder(path: currentFolderPath) else {
				throw YYFile.PathError.invalid(path)
			}
			
			guard let parent = currentFolder.parent else {
				throw YYFile.PathError.invalid(path)
			}
			
			path = path.replacingCharacters(in: path.startIndex..<parentReferenceRange.upperBound, with: parent.path)
			filledIn = true
		}
		
		if prependCurrentFolderPath, !filledIn {
			return currentDirectoryPath + "/" + path
		}
		
		return path
	}
}
