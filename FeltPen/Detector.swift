//
//  Detector.swift
//  Pods
//
//  Created by Aleksei Gordeev on 08/07/2017.
//
//

import Foundation

public typealias Attributes = [String : Any]

public struct DetectorSpot {
    
    public var attributes: Attributes

    public var range: NSRange
    
    public func apply(text: NSMutableAttributedString) {
        text.addAttributes(self.attributes, range: range)
    }
    
    public init(attributes: Attributes, range: NSRange) {
        self.attributes = attributes
        self.range = range
    }
    
    public init(_ detectorAttributes: [DetectorAttributeName : Any], range: NSRange) {
        var attributes: Attributes = [:]
        detectorAttributes.forEach({ (key, value) in
            attributes[key.rawValue] = value
        })
        
        self.init(attributes: attributes, range: range)
    }
}

public extension Array where Element == DetectorSpot {
    public func applySpots(text: NSMutableAttributedString) {
        for spot in self {
            spot.apply(text: text)
        }
    }
}


public struct DetectorResult: OptionSet {
    
    public typealias RawValue = Int
    
    public let rawValue: RawValue
    
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
    
    public init(_ rawValue: RawValue) {
        self.init(rawValue: rawValue)
    }
    
    public static let attributesChange = DetectorResult.init(1 << 0)
    
    public static let textChange = DetectorResult.init(1 << 1)
    
    public static let none = DetectorResult.init(0)
}


public protocol Detector {
    
    @discardableResult func process(text: NSMutableAttributedString) throws -> DetectorResult
    
}
