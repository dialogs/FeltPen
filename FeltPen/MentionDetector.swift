//
//  MentionDetector.swift
//  FeltPen
//
//  Created by Aleksei Gordeev on 26/09/2017.
//  Copyright © 2017 Aleksei Gordeev. All rights reserved.
//

import Foundation

public class MentionDetector: Detector {
    
    public struct SimplePatternConfig {
        
        public static let `default` = SimplePatternConfig.init()
        
        public var dotsAllowed: Bool = true
        public var minNickLength: Int = 3
        public var maxNickLength: Int = 25
        
        fileprivate var regexPattern: String {
            var template = "(?:^|[ {dots_allowed},#!$%^&*;:{}=_`~()/-])(@(?:all|[a-z0-9_]{{min_limit},{max_limit}}))"
            template = template.replacingOccurrences(of: "{dots_allowed}", with: dotsAllowed ? "." : "")
            template = template.replacingOccurrences(of: "{min_limit}", with: String(minNickLength))
            template = template.replacingOccurrences(of: "{max_limit}", with: String(maxNickLength))
            return template
        }
    }
    
    public var allowedNames: [String]? = nil
    
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
                                         range: NSRange.init(fullRangeOfString: text.string))
        for match in matches {
            let spot = DetectorSpot.init([DetectorAttributeName.mention : true], range: match.range)
            spots.append(spot)
        }
        
        spots.applySpots(text: text)
        
        return .none
    }
    
}
