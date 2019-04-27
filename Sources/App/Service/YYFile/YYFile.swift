//
//  YYFile.swift
//  SwiftProject
//
//  Created by yangyuan on 2018/11/29.
//  Copyright © 2018 huan. All rights reserved.
//

import Foundation

public final class YYFile {
	/// A reference to the temporary folder used by this file system
	public var temporaryFolder: Folder {
		return try! Folder(path: NSTemporaryDirectory(), using: fileManager)
	}
	
	/// A reference to the current user's home folder
	public var homeFolder: Folder {
		return try! Folder(path: ProcessInfo.processInfo.homeFolderPath, using: fileManager)
	}
	
	// A reference to the folder that is the current working directory
	public var currentFolder: Folder {
		return try! Folder(path: "")
	}
	
	fileprivate let fileManager: FileManager
	
	public init(using fileManager: FileManager = .default) {
		self.fileManager = fileManager
	}
}

public extension YYFile {
	@discardableResult
    func createFile(at path: String, contents: Data = Data()) throws -> File {
		let path = try fileManager.absolutePath(for: path)
		
		guard let parentPath = fileManager.parentPath(for: path) else {
			throw File.Error.write
		}
		
		do {
			let index = path.index(path.startIndex, offsetBy: parentPath.count + 1)
			let name = String(path[index...])
			return try createFolder(at: parentPath).createFile(named: name, contents: contents)
		} catch {
			throw File.Error.write
		}
	}
	
	@discardableResult
    func createFileIfNeeded(at path: String, contents: Data = Data()) throws -> File {
		if let existingFile = try? File(path: path, using: fileManager) {
			return existingFile
		}
		
		return try createFile(at: path, contents: contents)
	}
	
	@discardableResult
    func createFolder(at path: String) throws -> Folder {
		do {
			let path = try fileManager.absolutePath(for: path)
			try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
			return try Folder(path: path, using: fileManager)
		} catch {
			throw Folder.Error.creatingFolder
		}
	}
	
	@discardableResult
    func createFolderIfNeeded(at path: String) throws -> Folder {
		if let existingFolder = try? Folder(path: path, using: fileManager) {
			return existingFolder
		}
		
		return try createFolder(at: path)
	}
}


public extension YYFile {
	/**
	表示由文件系统存储的项目的类
	这是一个抽象基类，它有两个可公开初始化的具体实现`File`和`Folder`。
	您可以使用此类上提供的API来执行文件和文件夹支持的操作。
	*/
    class Item: Equatable, CustomStringConvertible {
		public let kind: Kind
		
		/// The path of the item, relative to the root of the file system
		public private(set) var path: String
		
		/// The name of the item (including any extension)
		public private(set) var name: String
		
		/// The name of the item (excluding any extension)
		public var nameExcludingExtension: String {
			guard let ext = ext else {
				return name
			}
			
			let endIndex = name.index(name.endIndex, offsetBy: -ext.count - 1)
			return String(name[..<endIndex])
		}
		
		/// Any extension that the item has
		public var ext: String? {
			let components = name.components(separatedBy: ".")
			return components.count > 1 ? components.last : nil
		}
		
		/// The date when the item was last modified
		public private(set) lazy var modificationDate = self.loadModificationDate()
		
		public var parent: Folder? {
			return fileManager.parentPath(for: path).flatMap{ try? Folder(path: $0, using: fileManager) }
		}
		
		fileprivate let fileManager: FileManager
		
		init(path: String, kind: Kind, using fileManager: FileManager) throws {
			guard !path.isEmpty else {
				throw PathError.empty
			}
			
			let path = try fileManager.absolutePath(for: path)
			
			guard fileManager.itemKind(atPath: path) == kind else {
				throw PathError.invalid(path)
			}
			
			self.path = path
			self.kind = kind
			self.fileManager = fileManager
			
			let pathComponents = path.pathComponents
			switch kind {
			case .file:
				self.name = pathComponents.last!
			case .folder:
				self.name = pathComponents[pathComponents.count - 2]
			}
		}
		
		public func rename(to newName: String, keepExtension: Bool = false) throws {
			guard let parent = parent else {
				throw OperationError.rename(self)
			}
			
			var newName = newName
			if keepExtension {
				if let ext = ext {
					let extString = ".\(ext)"
					if !newName.hasSuffix(extString) {
						newName += extString
					}
				}
			}
			
			var newPath = parent.path + newName
			if kind == .folder && !newPath.hasSuffix("/") {
				newPath += "/"
			}
			
			do {
				try fileManager.moveItem(atPath: path, toPath: newPath)
				name = newName
				path = newPath
			} catch {
				throw OperationError.rename(self)
			}
		}
		
		public func move(to newParent: Folder) throws {
			var newPath = newParent.path + name
			if kind == .folder && !newPath.hasSuffix("/") {
				newPath += "/"
			}
			
			do {
				try fileManager.moveItem(atPath: path, toPath: newPath)
				path = newPath
			} catch {
				throw OperationError.move(self)
			}
		}
		
		public func delete() throws {
			do {
				try fileManager.removeItem(atPath: path)
			} catch {
				throw OperationError.delete(self)
			}
		}
		
		// MARK: - Protocol
		public static func == (lhs: Item, rhs: Item) -> Bool {
			guard lhs.kind == rhs.kind else {
				return false
			}
			
			return lhs.path == rhs.path
		}
		
		public var description: String {
			return "\(kind)(name: \(name), path: \(path))"
		}
	}
}

public extension YYFile {
    final class File: Item, YYFileIterable {
		
		public enum Error: Swift.Error, CustomStringConvertible {
			case write
			case read
			
			/// A string describing the error
			public var description: String {
				switch self {
				case .write:
					return "Failed to write to file"
				case .read:
					return "Failed to read file"
				}
			}
		}
		
		public init(path: String, using fileManager: FileManager = .default) throws {
			try super.init(path: path, kind: .file, using: fileManager)
		}
		
		public func read() throws -> Data {
			do {
				return try Data(contentsOf: path.toFileURL())
			} catch {
				throw Error.read
			}
		}
		
		public func readAsString(encoding: String.Encoding = .utf8) throws -> String {
			guard let string = try String(data: read(), encoding: encoding) else {
				throw Error.read
			}
			
			return string
		}
		
		public func readAsInt() throws -> Int {
			guard let int = try Int(readAsString()) else {
				throw Error.read
			}
			
			return int
		}
		
		public func write(data: Data) throws {
			do {
				try data.write(to: path.toFileURL())
			} catch {
				throw Error.write
			}
		}
		
		public func write(string: String, encoding: String.Encoding = .utf8) throws {
			guard let data = string.data(using: encoding) else {
				throw Error.write
			}
			
			try write(data: data)
		}
		
		public func append(data: Data) throws {
			do {
				let handle = try FileHandle(forUpdating: path.toFileURL())
				handle.seekToEndOfFile()
				handle.write(data)
				handle.closeFile()
			} catch {
				throw Error.write
			}
		}
		
		public func append(string: String, encoding: String.Encoding = .utf8) throws {
			guard let data = string.data(using: encoding) else {
				throw Error.write
			}
			
			try append(data: data)
		}
		
	}
}

public extension YYFile {
    final class Folder: Item, YYFileIterable {
		public enum Error: Swift.Error, CustomStringConvertible {
			case creatingFolder
			
			public var description: String {
				switch self {
				case .creatingFolder:
					return "Failed to create folder"
				}
			}
		}
		
		public var files: FileSequence<File> {
			return makeFileSequence()
		}
		
		public var subfolders: FileSequence<Folder> {
			return makeSubfolderSequence()
		}
		
		public init(path: String, using fileManager: FileManager = .default) throws {
			var path = path
			if path.isEmpty {
				path = fileManager.currentDirectoryPath
			}
			
			if !path.hasSuffix("/") {
				path += "/"
			}
			try super.init(path: path, kind: .folder, using: fileManager)
		}
		
		public func file(named fileName: String) throws -> File {
			return try File(path: path, using: fileManager)
		}
		
		public func file(atPath filePath: String) throws -> File {
			return try File(path: path + filePath, using: fileManager)
		}
		
		public func containsFile(named fileName: String) -> Bool {
			return (try? file(named: fileName)) != nil
		}
		
		public func subfolder(named folderName: String) throws -> Folder {
			return try Folder(path: path + folderName, using: fileManager)
		}
		
		public func subfolder(atPath folderPath: String) throws -> Folder {
			return try Folder(path: path + folderPath, using: fileManager)
		}
		
		public func containsSubfolder(named folderName: String) -> Bool {
			return (try? subfolder(named: folderName)) != nil
		}
		
		@discardableResult
		public func createFile(named fileName: String, contents data: Data = .init()) throws -> File {
			let filePath = path + fileName
			
			guard fileManager.createFile(atPath: filePath, contents: data, attributes: nil) else {
				throw File.Error.write
			}
			
			return try File(path: filePath, using: fileManager)
		}
		
		@discardableResult
		public func createFile(named fileName: String, contents: String, encoding: String.Encoding = .utf8) throws -> File {
			let file = try createFile(named: fileName)
			try file.write(string: contents, encoding: encoding)
			return file
		}
		
		@discardableResult
		public func createFileIfNeeded(named fileName: String,
									   contents dataExpression: @autoclosure () -> Data = .init()) throws -> File {
			if let file = try? file(named: fileName) {
				return file
			}
			
			return try createFile(named: fileName, contents: dataExpression())
		}
		
		@discardableResult
		public func createSubfolder(named folderName: String) throws -> Folder {
			let subfolderPath = path + folderName
			
			do {
				try fileManager.createDirectory(atPath: subfolderPath, withIntermediateDirectories: false, attributes: nil)
				return try Folder(path: subfolderPath, using: fileManager)
			} catch {
				throw Error.creatingFolder
			}
		}
		
		@discardableResult
		public func createSubfolderIfNeeded(named folderName: String) throws -> Folder {
			if let existingFolder = try? subfolder(named: folderName) {
				return existingFolder
			}
			
			return try createSubfolder(named: folderName)
		}
		
		public func moveContents(to newParent: Folder, includeHidden:
			Bool = false) throws {
			try makeFileSequence(includeHidden: includeHidden).forEach { try $0.move(to: newParent) }
			try makeSubfolderSequence(includeHidden: includeHidden).forEach{ try $0.move(to: newParent) }
		}
		
		public func empty(includeHidden: Bool = false) throws {
			try makeFileSequence(includeHidden: includeHidden).forEach { try $0.delete() }
			try makeSubfolderSequence(includeHidden: includeHidden).forEach{ try $0.delete() }
		}
		
		@discardableResult
		public func copy(to folder: Folder) throws -> Folder {
			let newPath = folder.path + name
			
			do {
				try fileManager.copyItem(atPath: path, toPath: newPath)
				return try Folder(path: newPath)
			} catch {
				throw OperationError.copy(self)
			}
		}
		
		public func makeFileSequence(recursive: Bool = false, includeHidden: Bool = false) -> FileSequence<File> {
			return FileSequence(folder: self, recursive: recursive, includeHidden: includeHidden, using: fileManager)
		}
		
		public func makeSubfolderSequence(recursive: Bool = false, includeHidden: Bool = false) -> FileSequence<Folder> {
			return FileSequence(folder: self, recursive: recursive, includeHidden: includeHidden, using: fileManager)
		}
	}
}

// MARK: - FileSequence
public extension YYFile {
    class FileSequence<T: Item>: Sequence, CustomStringConvertible
		where T: YYFileIterable {
		public var count: Int {
			var count = 0
			forEach{ _ in count += 1 }
			return count
		}
		
		public var names: [String] {
			return map { $0.name }
		}
		
		public var first: T? {
			return makeIterator().next()
		}
		
		public var last: T? {
			var item: T?
			forEach { item = $0 }
			return item
		}
		
		private let folder: Folder
		private let recursive: Bool
		private let includeHidden: Bool
		private let fileManager: FileManager
		
		public init(folder: Folder, recursive: Bool, includeHidden: Bool, using fileManager: FileManager) {
			self.folder = folder
			self.recursive = recursive
			self.includeHidden = includeHidden
			self.fileManager = fileManager
		}
		
		public func makeIterator() -> FileIterator<T> {
			return FileIterator(folder: folder, recursive: recursive, includeHidden: includeHidden, using: fileManager)
		}
		
		public func move(to newParent: Folder) throws {
			try forEach{ try $0.move(to: newParent) }
		}
		
		public var description: String {
			return map { $0.description }.joined(separator: "\n")
		}
	}
	
    final class FileIterator<T: Item>: IteratorProtocol where T: YYFileIterable {
		private let folder: Folder
		private let recursive: Bool
		private let includeHidden: Bool
		private let fileManager: FileManager
		private lazy var itemNames: [String] = {
			self.fileManager.itemNames(inFolderAtPath: self.folder.path)
		}()
		private lazy var childIteratorQueue = [FileIterator]()
		private var currentChildIterator: FileIterator?
		
		fileprivate init(folder: Folder, recursive: Bool, includeHidden: Bool, using fileManager: FileManager) {
			self.folder = folder
			self.recursive = recursive
			self.includeHidden = includeHidden
			self.fileManager = fileManager
		}
		
		public func next() -> T? {
			if itemNames.isEmpty {
				if let next = currentChildIterator?.next() {
					return next
				}
				
				guard !childIteratorQueue.isEmpty else {
					return nil
				}
				
				currentChildIterator = childIteratorQueue.removeFirst()
				return next()
			}
			
			let nextItemName = itemNames.removeFirst()
			
			guard includeHidden || !nextItemName.hasPrefix(".") else {
				return next()
			}
			
			let nextItemPath = folder.path + nextItemName
			let nextItem = try? T(path: nextItemPath, using: fileManager)
			
			if recursive, let folder = (nextItem as? Folder) ?? (try? Folder(path: nextItemPath)) {
				let child = FileIterator(folder: folder, recursive: true, includeHidden: includeHidden, using: fileManager)
				childIteratorQueue.append(child)
			}
			
			return nextItem ?? next()
		}
	}
}

private extension YYFile.Item {
	func loadModificationDate() -> Date {
		return (try! fileManager.attributesOfItem(atPath: path))[.modificationDate] as! Date
	}
}






















