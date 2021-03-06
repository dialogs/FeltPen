//
//  NSAttributedString+FeltPen.swift
//  FeltPen
//
//  Created by Aleksei Gordeev on 19/09/2017.
//  Copyright © 2017 Aleksei Gordeev. All rights reserved.
//

import Foundation

public extension NSAttributedString {
    
    public func ranges(ofAttribute attrName: String,
                       options: NSAttributedString.EnumerationOptions = [],
                       includingNilValues: Bool = false) -> [NSRange] {
        let range = NSRange.range(of: self.string)
        var ranges: [NSRange] = []
        self.enumerateAttribute(NSAttributedStringKey(rawValue: attrName), in: range, options: options, using: { value, range, _ in
            if includingNilValues || value != nil {
                ranges.append(range)
            }
        })
        return ranges
    }
    
}
