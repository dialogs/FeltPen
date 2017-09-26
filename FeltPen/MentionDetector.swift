//
//  MentionDetector.swift
//  FeltPen
//
//  Created by Aleksei Gordeev on 26/09/2017.
//  Copyright © 2017 Aleksei Gordeev. All rights reserved.
//

import Foundation

public class MentionDetector: Detector {
    
    public var validNames: [String] = []
    
    /// You can't set value less than 1
    public var minNickLength: Int = 3
    public var maxNickLength: Int = 25
    
    @discardableResult public func process(text: NSMutableAttributedString) throws -> DetectorResult {
        
        
        
        return .none
    }
    
}
