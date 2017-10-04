//
//  DetectorAttribute.swift
//  Pods
//
//  Created by Aleksei Gordeev on 08/07/2017.
//
//

import Foundation


public struct DetectorAttributeName: RawRepresentable, Hashable {
    
    public typealias RawValue = String
    
    public let rawValue: RawValue
    
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
    
    public var isCharWrapped: Bool {
        return self.rawValue.hasPrefix(DetectorAttributeName.charWrappedPrefix)
    }
    
    public var charWrappedString: String? {
        guard self.isCharWrapped else {
            return nil
        }
        let prefixRange = self.rawValue.range(of: DetectorAttributeName.charWrappedPrefix)!
        let idx = self.rawValue.index(after: prefixRange.upperBound)
        return self.rawValue.substring(from: idx)
    }
    
    public init(_ rawValue: RawValue) {
        self.init(rawValue: rawValue)
    }
    
    /// Contains BasicDecoration
    private static let charWrappedPrefix = "lex.detector.attribute.char_wrapped"
    
    public static func charWrapped(_ charString: String) -> DetectorAttributeName {
        let rawValue = DetectorAttributeName.charWrappedPrefix.appending(".").appending(charString)
        return self.init(rawValue)
    }
    
    public static let bold = DetectorAttributeName.charWrapped("*")
    
    public static let strike = DetectorAttributeName.charWrapped("~")
    
    public static let italic = DetectorAttributeName.charWrapped("_")
    
    public static let url = DetectorAttributeName.init("lex.detector.attribute.url")
    
    public static let markdownUrl = DetectorAttributeName.init("lex.detector.attribute.markdown_url")
    
    public static let quote = DetectorAttributeName.init("lex.detector.attribute.quote")
    
    public static let codeBlock = DetectorAttributeName.init("lex.detector.attribute.code_block")
    
    public static let mention = DetectorAttributeName.init("lex.detector.attribute.mention")
    
    public static let allDefault: [DetectorAttributeName] = [
        .url,
        .markdownUrl,
        .quote,
        .codeBlock,
        .mention,
        .charWrapped(WrappersDetector.SearchingItem.backtick.charString),
        .charWrapped(WrappersDetector.SearchingItem.asteriks.charString),
        .charWrapped(WrappersDetector.SearchingItem.tilde.charString),
        .charWrapped(WrappersDetector.SearchingItem.underscore.charString)
    ]
    
    public var hashValue: Int {
        return self.rawValue.hashValue
    }
    
    public static func ==(lhs: DetectorAttributeName, rhs: DetectorAttributeName) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

public extension NSAttributedString {
    public func enumerateDetectorAttribute(_ attr: DetectorAttributeName,
                                           options: NSAttributedString.EnumerationOptions = [],
                                           range: NSRange? = nil,
                                           block: (Any?, NSRange, UnsafeMutablePointer<ObjCBool>) -> ()) {
        let targetRange = range ?? NSRange.range(of: self.string)
        self.enumerateAttribute(attr.rawValue, in: targetRange, options: options) { (value, range, stopPtr) in
            block(value, range, stopPtr)
        }
    }
    
    public func enumerateNonNilDetectorAttribute(_ attr: DetectorAttributeName,
                                                 options: NSAttributedString.EnumerationOptions = [],
                                                 range: NSRange? = nil,
                                                 block: (Any, NSRange, UnsafeMutablePointer<ObjCBool>) -> ()) {
        self.enumerateDetectorAttribute(attr) { (v, range, stopPtr) in
            guard let value = v else {
                return
            }
            block(value, range, stopPtr)
        }
    }
}
