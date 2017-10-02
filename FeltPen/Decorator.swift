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
}

public class Decorator: Detector {
    
    public var textChangingAllowed: Bool = true
    
    public var decoratableAttributes: [DetectorAttributeName] = []
    
    @discardableResult public func process(text: NSMutableAttributedString) throws -> DetectorResult {
        
        
        return .none
    }
    
}
