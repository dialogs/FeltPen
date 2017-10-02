//
//  NSRange+FeltPen.swift
//  FeltPen
//
//  Created by Aleksei Gordeev on 13/09/2017.
//  Copyright © 2017 Aleksei Gordeev. All rights reserved.
//

import Foundation


internal extension NSRange {
    
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

