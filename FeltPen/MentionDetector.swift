//
//  MentionDetector.swift
//  FeltPen
//
//  Created by Aleksei Gordeev on 26/09/2017.
//  Copyright © 2017 Aleksei Gordeev. All rights reserved.
//

import Foundation

public protocol MentionDetectorMentionValueProvider {
    func valueForName(_ name: String, mentionDetector: MentionDetector) -> Any?
}

public enum BasicMentionDetectorMentionValueWrapper: MentionDetectorMentionValueProvider {
    case dictionary([String : Any])
    case array([String])
    
    public func valueForName(_ name: String, mentionDetector: MentionDetector) -> Any? {
        switch self {
        case .dictionary(let dictionary): return dictionary[name]
        case .array(let array): return array.contains(name)
        }
    }
}

/**
 By default set values for detected attribute as 'true' if value provider is nil.
 You can provide your own custom values (like user ids) by setting 'valueProvider'.
 You can also use BasicMentionDetectorMentionValueWrapper with wrapped dictionary
 (keys are names and values are values for string attributes)
 */
public class MentionDetector: Detector {
    
    public struct SimplePatternConfig {
        
        public static let `default` = SimplePatternConfig.init()
        
        public var dotsAllowed: Bool = true
        public var minNickLength: Int = 3
        public var maxNickLength: Int = 25
        
        fileprivate var regexPattern: String {
            var template = "(?:^|[ {dots_allowed},#!$%^&*;:{}=_`~()/-])(@(?:all|[a-zA-Z0-9_]{{min_limit},{max_limit}}))"
            template = template.replacingOccurrences(of: "{dots_allowed}", with: dotsAllowed ? "." : "")
            template = template.replacingOccurrences(of: "{min_limit}", with: String(minNickLength))
            template = template.replacingOccurrences(of: "{max_limit}", with: String(maxNickLength))
            return template
        }
    }
    
    public var valueProvider: MentionDetectorMentionValueProvider? = nil
    
    private let regex: NSRegularExpression
    
    public init(config: SimplePatternConfig = SimplePatternConfig.default) {
        self.regex = try! NSRegularExpression.init(pattern: config.regexPattern, options: [])
    }
    
    public init(regex: NSRegularExpression) {
        self.regex = regex
    }
    
    @discardableResult public func process(text: NSMutableAttributedString) throws -> DetectorResult {
        
        var spots: [DetectorSpot] = []
        let matches = self.regex.matches(in: text.string,
                                         options: [],
                                         range: NSRange.range(of: text.string))
        for match in matches {
            guard match.numberOfRanges >= 2 else {
                continue
            }
            
            let range = match.rangeAt(1)
            
            guard let valueProvider = self.valueProvider else {
                let spot = DetectorSpot.init([DetectorAttributeName.mention : true], range: range)
                spots.append(spot)
                continue
            }
            
            let name = (text.string as NSString).substring(with: range)
            if let providerValue = valueProvider.valueForName(name, mentionDetector: self) {
                let spot = DetectorSpot.init([DetectorAttributeName.mention : providerValue], range: range)
                spots.append(spot)
            }
        }
        
        spots.applySpots(text: text)
        
        return .attributesChange
    }
    
}
