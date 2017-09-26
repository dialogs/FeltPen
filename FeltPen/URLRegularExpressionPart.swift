//
//  UrlPartRegex.swift
//  FeltPen
//
//  Created by Aleksei Gordeev on 19/09/2017.
//  Copyright © 2017 Aleksei Gordeev. All rights reserved.
//

import Foundation

func +(left: UrlRegex, right: UrlRegex) -> UrlRegex {
    return UrlRegex.init(rawValue: left.rawValue.appending(right.rawValue))
}

public struct UrlRegex: RawRepresentable {
    
    public typealias RawValue = String
    
    public let rawValue: String
    
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
    
    public init(_ rawValue: RawValue) {
        self.init(rawValue: rawValue)
    }
    
    public var optional: UrlRegex {
        let value = self.rawValue.appending("?")
        return type(of: self).init(rawValue: value)
    }
    
    public var closured: UrlRegex {
        let value = "(\(self.rawValue))"
        return type(of: self).init(value)
    }
    
    public enum RegexModifier {
        case boundedWithWhitespacesAndNewlines
    }
    
    public var regex: NSRegularExpression {
        return try! NSRegularExpression.init(pattern: self.rawValue, options: [])
    }
    
    public func modifiedRegex(_ modifiers: [RegexModifier]) -> NSRegularExpression {
        var pattern = self.rawValue
        if modifiers.contains(.boundedWithWhitespacesAndNewlines) {
            pattern = "(^|\\s)" + pattern + "(\\s|$)"
        }
        return try! NSRegularExpression.init(pattern: pattern, options: [])
    }
    
    /// Should begin with empty space / new line or punctuation character
    public static let begin = UrlRegex.init("([.,{()\\[\\]]|\\s|^)")
    
    /**
     Scheme names consist of a sequence of characters beginning with a letter
     and followed by any combination of letters, digits, plus ("+"), period ("."), or hyphen ("-").
     
     https://tools.ietf.org/html/rfc3986#section-3.1
     
     Optional.
     */
    public static let scheme = UrlRegex.init("([a-zA-Z][a-zA-Z0-9+-.]*)://")
    
    public static let host = UrlRegex.init("((\\p{L}|[0-9])+)\\.com")
    
    public static let path = UrlRegex.init("(/|\\?.*)[\\S]*")
    
    public static let end = UrlRegex.init("(?=([.,{}()\\[\\]])|$|\\s)")
    
    public static let wordEnd = UrlRegex.init("(?=($|\\s))")
    
    public static let inTextUrl: UrlRegex = {
        let url = (UrlRegex.scheme.closured.optional +
            UrlRegex.host.closured +
            UrlRegex.path.closured.optional).closured
        let wrapped = UrlRegex.begin + url + UrlRegex.wordEnd
        
        return wrapped
    }()
    
    public static let urlParts: UrlRegex = {
        let url = (UrlRegex.scheme.closured.optional +
            UrlRegex.host.closured +
            UrlRegex.path.closured.optional).closured
        let wrapped = UrlRegex.begin + url + UrlRegex.end
        return wrapped
    }()
    
    public enum UrlRegexClosure: Int {
        
        case hostWithDelimiter = 2
        case host = 3
        case authorityWithDelimiter = 4
        case authority = 5
        
    }
    
}
