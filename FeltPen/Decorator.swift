//
//  Decorator.swift
//  FeltPen
//
//  Created by Aleksei Gordeev on 27/09/2017.
//  Copyright © 2017 Aleksei Gordeev. All rights reserved.
//

import Foundation


public protocol DecoratorAttributeProvider {
    func decorationAttributes(forAttribute: DetectorAttributeName, decorator: Decorator) -> Attributes
    
    func font(decorator: Decorator, range: NSRange, values: Attributes) -> UIFont
    
}

public class Decorator: Detector {
    
    public var textChangingAllowed: Bool = true
    
    public lazy var defaultFont: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)
    
    public var decoratableAttributes: [DetectorAttributeName] = [.bold, .italic, .strike]
    
    @discardableResult public func process(text: NSMutableAttributedString) throws -> DetectorResult {
        
        if textChangingAllowed {
            
            let nsstring = text.string as NSString
            
            for item in decoratableAttributes {
                if item.isCharWrapped, let char = item.charWrappedString {
                    let ranges = text.ranges(ofAttribute: item.rawValue).reversed()
                    for range in ranges {
                        let charLength = (char as NSString).length
                        guard range.length > (char as NSString).length * 2 else {
                            continue
                        }
                        
                        let enclosingRange = NSRange.init(location: range.location, length: charLength)
                        let disclosingRange = NSRange.init(location: NSMaxRange(range) - charLength, length: charLength)
                        let wrapFound = (nsstring.substring(with: enclosingRange) == char &&
                            nsstring.substring(with: disclosingRange) == char)
                        if wrapFound {
                            text.replaceCharacters(in: disclosingRange, with: "")
                            text.replaceCharacters(in: enclosingRange, with: "")
                        }
                    }
                }
            }
        }
        
        self.setupAttributes(text: text, defaultFont: self.defaultFont)
        
        return .none
    }
    
    private static let defaultFontStyleAttributeNames: [DetectorAttributeName] = [.bold, .italic, .strike]
    
    private func setupAttributes(text: NSMutableAttributedString, defaultFont: UIFont) {
        
        struct Style: OptionSet, CustomStringConvertible {
            typealias RawValue = Int
            
            let rawValue: RawValue
            
            public init(rawValue: RawValue) {
                self.rawValue = rawValue
            }
            
            static let bold = Style.init(rawValue: 1<<0)
            static let italic = Style.init(rawValue: 1<<1)
            static let strike = Style.init(rawValue: 1<<2)
            
            var containsFontModifiers: Bool {
                return self.contains(.bold) || self.contains(.italic)
            }
            
            var description: String {
                var items = [String]()
                if self.contains(.bold) {
                    items.append("bold")
                }
                if self.contains(.italic) {
                    items.append("italic")
                }
                if self.contains(.strike) {
                    items.append("strike")
                }
                let total = items.count > 0 ? items.joined(separator: ", ") : "empty"
                return "<\(type(of: self)): \(total)>"
            }
            
            internal func attributes(defaultFont: UIFont? = nil) -> Attributes {
                var attributes = Attributes()
                
                if self.containsFontModifiers {
                    let font = defaultFont ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
                    var modifiers = UIFont.FontModifier()
                    print("mod on start: \(modifiers)")
                    if self.contains(.bold) {
                        print("inserting bold")
                        modifiers.insert(.bold)
                    }
                    if self.contains(.italic) {
                        print("inserting italic")
                        modifiers.insert(.italic)
                    }
                    print("mod on end: \(modifiers)")
                    let newFont = font.font(modified: modifiers)
                    attributes[NSFontAttributeName] = newFont
                }
                
                if self.contains(.strike) {
                    attributes[NSStrikethroughStyleAttributeName] = NSUnderlineStyle.patternSolid
                }
                
                return attributes
            }
            
        }
        
        var styles: [Int : Style] = [:]
        let applyRanges:([NSRange], Style) -> () = { ranges, style in
            for range in ranges {
                let indexes = IndexSet.init(integersIn: range.location..<NSMaxRange(range))
                indexes.forEach({ (idx) in
                    if let idxStyle = styles[idx] {
                        var newIdxStyle = idxStyle
                        newIdxStyle.insert(style)
                        styles[idx] = newIdxStyle
                    }
                    else {
                        styles[idx] = style
                    }
                })
            }
        }
        
        let boldRanges = text.ranges(ofAttribute: DetectorAttributeName.bold.rawValue)
        applyRanges(boldRanges, .bold)
        
        let italicRanges = text.ranges(ofAttribute: DetectorAttributeName.italic.rawValue)
        applyRanges(italicRanges, .italic)
        
        let strokeRanges = text.ranges(ofAttribute: DetectorAttributeName.strike.rawValue)
        applyRanges(strokeRanges, .strike)
        
        let valuedRanges = styles.buildValuedRanges()
        valuedRanges.forEach {entry in
            let attributes = entry.value.attributes(defaultFont: defaultFont)
            let range = entry.key
            print("\nApplying [\(range)]: \(entry.value):\n\(attributes)\n")
            text.addAttributes(entry.value.attributes(defaultFont: defaultFont), range: entry.key)
        }
    }
    
}



internal extension Dictionary where Key == Int, Value: Equatable {
    
    internal class ValuedRange {
        var range: NSRange
        let value: Value
        
        internal func append(to: Int) {
            range.length = to - range.location + 1
        }
        
        internal init(range: NSRange, value: Value) {
            self.range = range
            self.value = value
        }
        
        internal convenience init(location: Int, value: Value) {
            let range = NSRange(location: location, length: 1)
            self.init(range: range, value: value)
        }
        
    }
    
    internal func buildValuedRanges() -> [NSRange : Value] {
        let sortedKeys = self.keys.sorted()
        
        var results: [NSRange : Value] = [:]
        
        var currentRange: ValuedRange? = nil
        
        for idx in sortedKeys {
            let value = self[idx]!
            if let range = currentRange {
                if range.value == value {
                    range.append(to: idx)
                }
                else {
                    results[range.range] = range.value
                    currentRange = ValuedRange.init(location: idx, value: value)
                }
            }
            else {
                currentRange = ValuedRange.init(location: idx, value: value)
            }
        }
        
        if let range = currentRange {
            results[range.range] = range.value
        }
        
        return results
    }
    
}
