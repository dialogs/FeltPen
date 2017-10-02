//
//  UrlDetector.swift
//  FeltPen
//
//  Created by Aleksei Gordeev on 11/07/2017.
//  Copyright © 2017 Aleksei Gordeev. All rights reserved.
//

import Foundation


public class UrlDetector: Detector, CustomStringConvertible {
    
    public let config: Config
    
    public struct Config {
        
        public static let `default` = Config.init()
        
        var searchLinksInMarkdownRanges: Bool = false
        
        var subdetectors: SubdetectorType = .all
        
        /// Default scheme for building urls. Default is http
        var defaultScheme: String = "http"
        
        var allowedDomains: Set<String>? = Config.defaultAllowedFirstLevelDomains
        
        public struct SubdetectorType: OptionSet {
            
            public typealias RawValue = Int
            
            public let rawValue: Int
            
            public init(rawValue: RawValue) {
                self.rawValue = rawValue
            }
            public static let markdownUrlDetector = SubdetectorType.init(rawValue: 1 << 0)
            
            public static let linkDetector = SubdetectorType.init(rawValue: 1 << 1)
            
            public static let all: SubdetectorType = [.markdownUrlDetector, .linkDetector]
        }
    }
    
    public init(config: Config = Config.default) {
        self.config = config
    }
    
    @discardableResult public func process(text: NSMutableAttributedString) throws -> DetectorResult {
        
        if self.config.subdetectors.contains(.markdownUrlDetector) {
            self.processMarkdownLinks(text: text)
        }
        
        if self.config.subdetectors.contains(.linkDetector) {
            self.processLinks(text: text, ignoreMarkdownLinks: !self.config.searchLinksInMarkdownRanges)
        }
        
        return [.attributesChange]
    }
    
    public var description: String {
        var patterns:[String: String] = [:]
        if self.config.subdetectors.contains(.markdownUrlDetector) {
            patterns["markdown"] = type(of: self).markdownUrlDetector.pattern
        }
        if self.config.subdetectors.contains(.linkDetector) {
            patterns["in-text urls"] = type(of: self).urlDetector.pattern
        }
        return "<\(type(of: self)), patterns: \(patterns)>"
    }
    
    // MARK: Private
    
    private static let markdownUrlDetector: NSRegularExpression = {
        let pattern = "(?:__|[*#])|\\[(.*?)\\]\\((.*?)\\)"
        return try! NSRegularExpression(pattern: pattern, options: [])
    }()
    
    private enum BasicLinkClosuresInfo: Int {
        case enclosing = 2
        case whole = 3
        case scheme = 5
        case host = 6
        case pathAndQery = 8
    }
    
    private static let urlDetector: NSRegularExpression = {
        let begin = "([.,]|\\s|^)"
        let pattern = "([.,]|\\s|^)"
            + "([{(\\[]*)"
            + "("
            + "(([a-zA-Z][a-zA-Z0-9+-.]*)://)?"
            //+ "(((\\p{L}|[0-9])+)\\.((\\p{L}|[0-9])+))"
            + "(([^/?])+)"
            + "((/|\\?.*)[\\S]*)?"
            + ")"
            + "([)}\\]])*"
            + "(?=[.,;]|\\s|$)"
        return try! NSRegularExpression(pattern: pattern, options: [])
    }()
    
    @discardableResult private func processMarkdownLinks(text: NSMutableAttributedString) -> Bool {
        let textRange = NSRange(location: 0, length: text.length)
        let matches = type(of: self).markdownUrlDetector.matches(in: text.string, options: [], range: textRange)
        let results = matches.markdownUrlMatches
        for result in results {
            result.apply(text: text)
        }
        
        return matches.count > 0
    }
    
    @discardableResult private func processLinks(text: NSMutableAttributedString, ignoreMarkdownLinks: Bool = true) -> Bool {
        
        let markdownRanges = text.ranges(ofAttribute: DetectorAttributeName.markdownUrl.rawValue)
        let allowedRanges = NSRange.range(of: text.string).subranges(rangesToExtract: markdownRanges)
        
        guard allowedRanges.count > 0 else {
            return false
        }
        
        let regex = type(of: self).urlDetector
        
        let string = text.string
        
        var spots: [DetectorSpot] = []
        
        for range in allowedRanges {
            let matches = regex.matches(in: string, options: [], range: range)
            for match in matches {
                
                guard var wholeRange = match.unicodeScalarRangeOfClosure(idx: BasicLinkClosuresInfo.whole.rawValue, string: string) else {
                    continue
                }
                
                guard let host = match.stringForClosure(BasicLinkClosuresInfo.host, string: string),
                    !host.isEmpty else {
                        continue
                }
                
                guard self.isValidHost(host) else {
                    continue
                }
                
                let scheme = match.stringForClosure(BasicLinkClosuresInfo.scheme, string: string)
                var path = match.stringForClosure(BasicLinkClosuresInfo.pathAndQery, string: string)
                var query: String? = nil
                
                var fixedPathChanges = 0
                if var fixedPath = path {
                    let beforeFixLastIdx = fixedPath.unicodeScalars.endIndex
                    fixedPath = self.removeCommas(fixedPath)
                    
                    if let disclosingClosure = self.findDisclosingClosure(text: string, at: NSRange.range(of: string)) {
                        
//                        let range = string.startIndex..<string.endIndex
//                        string.enumerateSubstrings(in: range, options: .byLines, { (str, range, effRange, stop) in
//                            
//                        })
                        
                        if let range = match.unicodeScalarRangeOfClosure(idx: BasicLinkClosuresInfo.enclosing.rawValue, string: string) {
                            let enclosing = String.init(string.unicodeScalars[range])
                            let stack = self.buildEnclosingStack(enclosing)
                            fixedPath = self.fixPath(fixedPath, stack: stack)
                        }
                        else {
                            
                            // TODO: Check if it last item of list in braces, like (link1, link2, *link3*)
                            print("Closure found in \(string)")
                            
                            //                            let nsstring = string as NSString
                            //                            let paragraphRange = nsstring.paragraphRange(for: range)
                            //                            let paragraph = nsstring.substring(with: paragraphRange)
                        }
                    }
                    
                    
                    fixedPathChanges = beforeFixLastIdx.encodedOffset - fixedPath.unicodeScalars.endIndex.encodedOffset
                    
                    let items = self.breakPathAndQuery(fixedPath)
                    path = items.path
                    if !items.query.isEmpty {
                        query = items.query
                    }
                }
                
                if fixedPathChanges > 0 {
                    let newUpperBoundOffset = wholeRange.upperBound.encodedOffset - fixedPathChanges
                    let newUpperBound = String.UnicodeScalarIndex.init(encodedOffset: newUpperBoundOffset)
                    wholeRange = wholeRange.lowerBound..<newUpperBound
                }
                
                var components = URLComponents.init()
                components.host = host
                components.scheme = scheme ?? self.config.defaultScheme
                components.path = path ?? ""
                components.query = query
                
                guard let url = components.url else {
                    print("Fail to create url from \(components)")
                    continue
                }
                
                let convertedRange = NSRange.fromUnicodeScalar(wholeRange)
                let spot = DetectorSpot.init([DetectorAttributeName.url : url], range: convertedRange)
                spots.append(spot)
            }
        }
        
        spots.applySpots(text: text)
        
        return spots.count > 0
    }
    
    private func fixPath(_ path: String, stack: [ClosurableElement]) -> String {
        var fixedPath = path
        for element in stack {
            guard fixedPath.count > 0 else {
                break
            }
            if String.init(fixedPath.last!) == element.disclosing {
                fixedPath.removeLast()
            }
            else {
                break
            }
        }
        return fixedPath
    }
    
    private func findDisclosingClosure(text: String, at range: NSRange) -> ClosurableElement? {
        let possibleClosureLocation = NSMaxRange(range) - 1
        let possibleClosureRange = NSRange(location: possibleClosureLocation, length: 1)
        let possibleClosure = (text as NSString).substring(with: possibleClosureRange)
        return ClosurableElement.all.first(where: { $0.disclosing == possibleClosure })
    }
    
    private func buildEnclosingStack(_ string: String) -> [ClosurableElement] {
        let elements = ClosurableElement.all
        var foundElements: [ClosurableElement] = []
        for char in string {
            guard let element = elements.first(where: { return $0.enclosing == String(char)}) else {
                break
            }
            foundElements.append(element)
        }
        return foundElements
    }
    
    private enum ClosurableElement: CustomStringConvertible {
        case parenthes
        case squareBracket
        case curlyBracket
        case angleBracket
        
        var enclosing: String {
            switch self {
            case .squareBracket: return "["
            case .parenthes: return "("
            case .curlyBracket: return "{"
            case .angleBracket: return "<"
            }
        }
        
        var disclosing: String {
            switch self {
            case .squareBracket: return "]"
            case .parenthes: return ")"
            case .curlyBracket: return "}"
            case .angleBracket: return ">"
            }
        }
        
        var description: String {
            return "<\(String(describing: type(of: self))): \(self.enclosing)\(self.disclosing)>"
        }
        
        static let all: [ClosurableElement] = [.parenthes, .squareBracket, .curlyBracket, .angleBracket]
    }
    
    private func breakPathAndQuery(_ string: String) -> (path: String, query: String) {
        guard let firstQuestionIndex =  string.index(of: "?") else {
            return (path: string, query: "")
        }
       
        let path = string.substring(to: firstQuestionIndex)
        
        var query = ""
        
        let queryBeginIndex = string.index(firstQuestionIndex, offsetBy: 1)
        if string.endIndex > queryBeginIndex {
            query = string.substring(from: queryBeginIndex)
        }
        return (path:path, query: query)
    }
    
    private static let endingCommaRegex = try! NSRegularExpression.init(pattern: "[ ,.]*$", options: [])
    
    private func fixSlashedQuery(_ string: String) -> String {
        guard let queryRange = string.range(of: "/?") else {
            return string
        }
        var path = string
        path = path.replacingCharacters(in: queryRange, with: "?")
        return path
    }
    
    private func removeCommas(_ string: String) -> String {
        let result = type(of: self).endingCommaRegex.stringByReplacingMatches(in: string,
                                                                              options: [],
                                                                              range: .range(of: string),
                                                                              withTemplate: "")
        return result
    }
    
    private func fixedPath(_ unfixedPath: String) -> String {
        var path = unfixedPath
        
        if path.hasPrefix("/?") {
            let beginIndex = path.startIndex
            let endIndex = path.index(beginIndex, offsetBy: 2)
            let range: Range<String.Index> = beginIndex..<endIndex
            path = path.replacingOccurrences(of: path, with: "/", options: [], range: range)
        }
        
        let removeLastChar: ()->() = {
            path = path.substring(to: path.index(before: path.endIndex))
        }
        
        if path.hasSuffix(",") {
            removeLastChar()
        }
        
        if path.hasSuffix(")") && !self.isCurlyClosureBalancedInPath(path) {
            removeLastChar()
        }
        return path
    }
    
    private let enclosingRegex = try! NSRegularExpression.init(pattern: "\\(", options: [])
    private let disclosingRegex = try! NSRegularExpression.init(pattern: "\\)", options: [])
    
    private func isCurlyClosureBalancedInPath(_ path: String) -> Bool {
        let enclosingMatches = enclosingRegex.matches(in: path, options: [], range: .range(of: path))
        let disclosingMatches = disclosingRegex.matches(in: path, options: [], range: .range(of: path))
        return disclosingMatches.count > enclosingMatches.count
    }
    
    private func markdownLinkRanges(in attrString: NSAttributedString) -> [NSRange] {
        let attr = DetectorAttributeName.markdownUrl.rawValue
        let range = NSRange.range(of: attrString.string)
        var ranges: [NSRange] = []
        attrString.enumerateAttribute(attr, in: range, options: [], using: { value, range, _ in
            if value != nil {
                ranges.append(range)
            }
        })
        return ranges
    }
    
    private static let firstDomainRegex = try! NSRegularExpression.init(pattern: "\\.((\\p{L}|[0-9])*)$", options: [])
    private func isValidHost(_ string: String) -> Bool {
        guard let match = type(of: self).firstDomainRegex.firstMatch(in: string,
                                                                     options: [],
                                                                     range: .range(of: string)) else {
                                                                        return false
        }
        
        guard match.range.location != NSNotFound, match.range.length > 0 else {
            return false
        }
        
        if let allowedDomains = self.config.allowedDomains {
            
            let firstDomainClosureIdx = 1
            guard firstDomainClosureIdx < match.numberOfRanges else {
                return false
            }
            
            let domainOnlyRange = match.rangeAt(firstDomainClosureIdx)
            guard domainOnlyRange.location != NSNotFound, domainOnlyRange.length > 0 else {
                return false
            }
            
            let domain = (string as NSString).substring(with: domainOnlyRange)
            return allowedDomains.contains(domain)
        }
        return true
    }
    
}

fileprivate extension Array where Element == NSTextCheckingResult {
    
    fileprivate var markdownUrlMatches: [UrlDetector.MarkdownUrlRange] {
        
        let matches = self.rangesOfClosures(indexes: [0, 1, 2])
        return matches.map({ _, ranges in
            return UrlDetector.MarkdownUrlRange(range: ranges[0], textRange: ranges[1], linkRange: ranges[2])
        })
    }
    
}


public extension UrlDetector {
    
    fileprivate struct MarkdownUrlRange {
        
        fileprivate let range: NSRange
        fileprivate let textRange: NSRange
        fileprivate let linkRange: NSRange
        
        fileprivate func apply(text: NSMutableAttributedString) {
            let string = text.string as NSString
            
            let urlText = string.substring(with: textRange)
            let urlLink = string.substring(with: linkRange)
            let url = URL.init(string: urlLink)
            let fullUrlAttr = MarkdownUrl.init(text: urlText, link: urlLink, url: url)
            
            text.addAttribute(DetectorAttributeName.markdownUrl.rawValue, value: fullUrlAttr, range: range)
        }
    }
    
    public enum SearchingItem {
        
        // Search for completely correct urls like http://google.com
        case normal
        
        // Search for invalid urls, and tries to correct them, like http://xn--h1aax.xn–p1ai/smi/18390/ or кто.рф
        case normalizable
        
        // Search for markdown urls like [foo](https://google.com)
        case markdown
    }
    
    
    public struct MarkdownUrl {
        
        public let text: String
        public let link: String
        public var url: URL?
        
        public init(text: String, link: String, url: URL? = nil) {
            self.text = text
            self.link = link
            self.url = url
        }
    }
    
}
