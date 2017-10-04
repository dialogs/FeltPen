//
//  NSRange+FeltPen.swift
//  FeltPen
//
//  Created by Aleksei Gordeev on 13/09/2017.
//  Copyright © 2017 Aleksei Gordeev. All rights reserved.
//

import Foundation


internal extension NSRange {
    
    var asRange: CountableRange<Int> {
        return self.location..<self.length
    }
    
    internal func subranges(rangesToExtract: [NSRange]) -> [NSRange] {
        
        let unionRangesToExtract = rangesToExtract.unionRanges
        
        guard unionRangesToExtract.count > 0 else {
            return [self]
        }
        
        var ranges: [NSRange] = []
        let lastIdx = NSMaxRange(self)
        var startIdx: NSInteger = 0
        var endIdx: NSInteger = 0
        
        for rangeToExtract in unionRangesToExtract {
            let intersection = NSIntersectionRange(self, rangeToExtract)
            if intersection.length > 0 {
                endIdx = intersection.location
                
                ranges.append(NSRange.init(location: startIdx, length: endIdx - startIdx))
                
                startIdx = NSMaxRange(intersection)
                if startIdx == NSMaxRange(self) {
                    break
                }
            }
        }
        
        
        if startIdx != NSMaxRange(self) {
            let range = NSRange(location: startIdx, length: lastIdx - startIdx)
            ranges.append(range)
        }
        
        
        return ranges
    }
    
    // For some reason this method is unavailable in tests
    internal static func range(of string: String) -> NSRange {
        return NSRange.init(location: 0, length: string.characters.count)
    }
    
    internal static func range(from: Int, to: Int) -> NSRange {
        return NSRange.init(location: from, length: to - from)
    }
    
    internal func isEqualTo(_ range: NSRange) -> Bool {
        return NSEqualRanges(self, range)
    }
    
    internal var descr: String {
        return NSStringFromRange(self)
    }
    
    internal func toUnicodeScalar(string: String) -> Range<String.UnicodeScalarIndex> {
        let swiftRange = self.toRange()!
        let uniRangeStart = string.unicodeScalars.index(string.startIndex, offsetBy: swiftRange.lowerBound)
        let uniRangeEnd = string.unicodeScalars.index(string.startIndex, offsetBy: swiftRange.upperBound)
        let uniRange = uniRangeStart..<uniRangeEnd
        return uniRange
    }
    
    internal static func fromUnicodeScalar(_ range: Range<String.UnicodeScalarIndex>) -> NSRange {
        let range = NSRange.init(location: range.lowerBound.encodedOffset,
                                 length: (range.upperBound.encodedOffset - range.lowerBound.encodedOffset))
        return range
    }
    
    
    internal enum RelationType {
        
        /// Comparable range is shifted and has no intersection
        case offset(Int)
        
        /// The original range and the comparable one are equal
        case same
        
        /// The comparable range contained by the original one
        case contained
        
        /// The comparable range contains the original one
        case contains
        
        /// The comparable and original range has intersection.
        case intersects(NSRange, originalPart: NSRange, comparablePart: NSRange)
    }
    
    internal func relationType(of range: NSRange) -> RelationType {
        let intersection = NSIntersectionRange(self, range)
        guard intersection.location != NSNotFound && intersection.length > 0 else {
            return .offset(range.location - self.location)
        }
        
        guard !NSEqualRanges(self, range) else {
            return .same
        }
        
        if self.isContains(range: range) {
            return .contained
        }
        
        if range.isContains(range: self) {
            return .contains
        }
        
        
        let originalTail = self.removingTail(range: intersection)
        let comparableTail = range.removingTail(range: intersection)
        
        return .intersects(intersection, originalPart: originalTail, comparablePart: comparableTail)
    }
    
    internal static var undefined = NSRange(location: NSNotFound, length: 0)
    
    internal var isUndefined: Bool {
        return self.location == NSNotFound && length == 0
    }
    
    internal var isKindOfUndefined: Bool {
        return self.location == NSNotFound || length == 0
    }
    
    internal func removingTail(range: NSRange) -> NSRange {
        let resultLength = self.length - range.length
        guard resultLength > 0 else {
            return NSRange.undefined
        }
        
        if range.location == self.location {
            return NSRange(location: NSMaxRange(range), length: resultLength)
        }
        else if NSMaxRange(range) == NSMaxRange(self) {
            return NSRange(location: self.location, length: resultLength)
        }
        return NSRange.undefined
    }
    
    internal func isContains(range: NSRange) -> Bool {
        return range.location >= self.location && range.length <= self.length
    }
    
}

public extension Array where Element == NSRange {
    
    var rangesSortedByLocation: [NSRange] {
        return self.sorted(by: { $0.0.location < $0.1.location})
    }
    
    var unionRanges: [NSRange] {
        guard self.count > 1 else {
            return self
        }
        
        let ranges = self.rangesSortedByLocation
        
        var unionRanges: [NSRange] = []
        var currentBiggestRange: NSRange! = nil
        
        var indexesToSearch = IndexSet.init(integersIn: 0..<count)
        
        let enumeratedRanges = ranges.enumerated()
        
        for i in 0..<self.count {
            
            guard indexesToSearch.contains(i) else {
                continue
            }
            
            indexesToSearch.remove(i)
            currentBiggestRange = ranges[i]
            
            for entry in enumeratedRanges {
                
                guard indexesToSearch.contains(entry.offset) else {
                    continue
                }
                
                if NSIntersectionRange(currentBiggestRange, entry.element).length > 0 ||
                    entry.element.location == NSMaxRange(currentBiggestRange) {
                    currentBiggestRange = NSUnionRange(currentBiggestRange, entry.element)
                    indexesToSearch.remove(entry.offset)
                }
            }
            
            unionRanges.append(currentBiggestRange)
        }
        return unionRanges
    }
    
}


/*
 
 private func foundIntersection(_ range1: NSRange, _ range2: NSRange) -> RangeIntersection {
 
 let intersection = NSIntersectionRange(range1, range2)
 guard intersection.location != NSNotFound && intersection.length > 0 else {
 return .none
 }
 
 guard !NSEqualRanges(range1, range2) else {
 return .same
 }
 
 if range1.length == intersection.length {
 return .contains(container: range1, contained: range2)
 }
 else if range2.length == intersection.length {
 return .contains(container: range2, contained: range1)
 }
 
 
 
 let beforeRange: NSRange
 let afterRange: NSRange
 if range1.location < intersection.location {
 beforeRange = NSRange(location: range1.location, legth: intersection.location - range1.location)
 }
 else {
 
 }
 
 return .none
 }
 */

