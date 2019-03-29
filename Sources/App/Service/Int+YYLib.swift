//
//  Int+YYLib.swift
//  SwiftProject
//
//  Created by yangyuan on 2018/1/18.
//  Copyright © 2018年 huan. All rights reserved.
//

import Foundation



// MARK: - Properties
public extension Int {
	/// CountableRange 0..<Int.
	public var countableRange: CountableRange<Int> {
		return 0..<self
	}
	
	/// CountableClosedRange 0...Int.
	public var closedRange: CountableClosedRange<Int> {
		return 0...self
	}
	
	/// SwifterSwift: Radian value of degree input.
	public var degreesToRadians: Double {
		return Double.pi * Double(self) / 180.0
	}
	
	/// SwifterSwift: Degree value of radian input
	public var radiansToDegrees: Double {
		return Double(self) * 180 / Double.pi
	}
	
}


public extension Int {
	
	public func toBool() -> Bool {
		return self == 0 ? false : true
	}
	
	public func toUInt() -> UInt {
		return UInt(self)
	}
	
	public func toDouble() -> Double {
		return Double(self)
	}
	
	public func toFloat() -> Float {
		return Float(self)
	}
	
	
	public func toString() -> String {
		return "\(self)"
	}
    
    public func toArray(containsZero: Bool = false) -> [Int] {
        var arr = Array(closedRange)
        if !containsZero {
            arr.removeFirst()
        }
        
        return arr
    }
}

























