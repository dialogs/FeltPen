//
//  NSTextCheckingResult+FeltPen.swift
//  FeltPen
//
//  Created by Aleksei Gordeev on 12/09/2017.
//  Copyright © 2017 Aleksei Gordeev. All rights reserved.
//

import Foundation

public extension NSTextCheckingResult {
    public var ranges: [NSRange] {
        var ranges: [NSRange] = []
        for i in 0..<self.numberOfRanges {
            ranges.append(self.rangeAt(i))
        }
        return ranges
    }
    
    public var rangesDescription: String {
        let rangeDescriptions: [String] = self.ranges.map({ NSStringFromRange($0)})
        return rangeDescriptions.joined(separator: ", ")
    }
}

public extension NSTextCheckingResult {
    
    public func unicodeScalarRangeOfClosure(idx: Int, string: String, allowEmptyRanges: Bool = false) -> Range<String.UnicodeScalarIndex>? {
        guard let range = self.rangeOfClosure(idx: idx, allowEmptyRanges: allowEmptyRanges) else {
            return nil
        }
        return range.toUnicodeScalar(string: string)
    }
    
    public func rangeOfClosure(idx: Int, allowEmptyRanges: Bool = false) -> NSRange? {
        guard idx < self.numberOfRanges else {
            return nil
        }
        let range = self.rangeAt(idx)
        if allowEmptyRanges || range.length > 0 {
            return range
        }
        return nil
    }
    
    public func rangeOfClosure<Closure: RawRepresentable>(_ closure: Closure, allowEmptyRanges: Bool = false) -> NSRange?
        where Closure.RawValue == Int {
            let idx = closure.rawValue
            return self.rangeOfClosure(idx: idx, allowEmptyRanges: allowEmptyRanges)
    }
    
    public func stringForClosure(idx: Int, string: String, allowEmptyRanges: Bool = false) -> String? {
        guard let unicodeRange = self.unicodeScalarRangeOfClosure(idx: idx, string: string, allowEmptyRanges: allowEmptyRanges) else {
            return nil
        }
        
        let unicodeScalars = string.unicodeScalars[unicodeRange]
        return String.init(unicodeScalars)
    }
    
    public func stringForClosure<Closure: RawRepresentable>(_ closure: Closure,
                                 string: String,
                                 allowEmptyRanges: Bool = false) -> String?
        where Closure.RawValue == Int {
            return self.stringForClosure(idx: closure.rawValue, string: string, allowEmptyRanges: allowEmptyRanges)
    }
}

public extension Array where Element == NSTextCheckingResult {
    
    public typealias ClosureRange = (NSInteger, NSRange)
    
    public typealias ClosureRanges = (NSInteger, [NSRange])
    
    public func rangesOfClosure(idx: Int) -> [ClosureRange] {
        return self.enumerated().flatMap({ matchIdx, match in
            guard match.numberOfRanges > idx else {
                return nil
            }
            return ClosureRange(idx, match.rangeAt(idx))
        })
    }
    
    public func rangesOfClosures(indexes: IndexSet) -> [ClosureRanges] {
        guard let maxIndex = indexes.max() else {
            return []
        }
        
        return self.enumerated().flatMap({ idx, match in
            guard match.numberOfRanges > maxIndex else {
                return nil
            }
            
            let ranges: [NSRange] = indexes.map({ match.rangeAt($0) })
            return ClosureRanges(idx, ranges)
        })
    }
    
}
