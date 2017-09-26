//
//  WrappersDetector.swift
//  Pods
//
//  Created by Aleksei Gordeev on 08/07/2017.
//
//

import Foundation

/**
 Basic detector which search strings using prefix and suffix symbols.
 
 Processes string and settings attributes.
 
 Related Attribute Value: SpotAttribute
 
 */
public class WrappersDetector: Detector {
    
    public let searchingItems: [SearchingItem]
    
    
    // MARK: init
    
    public init(searchingItems: [SearchingItem] = SearchingItem.all) {
        self.searchingItems = searchingItems
    }
    
    @discardableResult public func process(text: NSMutableAttributedString) throws -> DetectorResult {
        guard  !self.searchingItems.isEmpty else {
            return []
        }
        
        var spots: [DetectorSpot] = []
        
        for item in searchingItems {
            let spotAttribute = SpotAttribute.init(item: item)
            let regex = type(of: self).createRegex(item: item)
            let range = NSRange(location: 0, length: text.string.characters.count)
            let matches = regex.matches(in: text.string, options: [], range: range)
            let ranges = matches.rangesOfClosure(idx: 1)
            let itemSpots: [DetectorSpot] = ranges.map({ _, range in
            return DetectorSpot.init([.charWrapped(item.charString): spotAttribute], range: range)
            })
            spots.append(contentsOf: itemSpots)
        }
        
        for spot in spots {
            spot.apply(text: text)
        }
        
        return DetectorResult.attributesChange
    }
    
    
    internal static func createRegex(item: SearchingItem) -> NSRegularExpression {
        let searchingChar = item.charString
        
        let escapedChar = NSRegularExpression.escapedPattern(for: searchingChar)
        let allowedCharsPattern = "[ .,#!$%^&;:{}=_`~()\\/-/*]"
        
        let fixedAllowedCharsPattern = allowedCharsPattern.replacingOccurrences(of: escapedChar, with: "")
        
        let searchingTarget = "(\(escapedChar)[^\(searchingChar)]+\(escapedChar))"
        
        let beginPattern = "(?:^|\(fixedAllowedCharsPattern))"
        let endPattern = "(?:$|\(fixedAllowedCharsPattern))"
        
        let pattern = beginPattern.appending(searchingTarget).appending(endPattern)
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        
        return regex
    }
    
}


// MARK: Nested Types

public extension WrappersDetector {
    
    public struct SearchingItem: Hashable, CustomStringConvertible {
        
        public let charString: String
        
        public init(_ charString: String) {
            self.charString = charString
        }
        
        // MARK: Equality
        
        public static func ==(lhs: SearchingItem, rhs: SearchingItem) -> Bool {
            return lhs.charString == rhs.charString
        }
        
        public var hashValue: Int {
            return self.charString.hash
        }
        
        public var description: String {
            let pattern = WrappersDetector.createRegex(item: self).pattern
            return "SearchingItem: \(pattern)"
        }
        
        // MARK: Static Constants
        
        public static let backtick = SearchingItem.init("`")
        
        public static let asteriks = SearchingItem.init("*")
        
        public static let underscore = SearchingItem.init("_")
        
        public static let tilde = SearchingItem.init("~")
        
        public static let all: [SearchingItem] = [.backtick, .asteriks, .underscore, .tilde]
        
        public var detectorAttributeName: DetectorAttributeName {
            return DetectorAttributeName.charWrapped(self.charString)
        }
        
    }
    
    
    public struct SpotAttribute: Hashable {
        public let item: SearchingItem
        
        public init(item: SearchingItem) {
            self.item = item
        }
        
        public var hashValue: Int {
            return self.item.hashValue
        }
        
        public static func ==(lhs: SpotAttribute, rhs: SpotAttribute) -> Bool {
            return lhs.item == rhs.item
        }
    }
}
