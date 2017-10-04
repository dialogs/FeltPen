//
//  UIFont+FeltPen.swift
//  FeltPen
//
//  Created by Aleksei Gordeev on 03/10/2017.
//  Copyright © 2017 Aleksei Gordeev. All rights reserved.
//

import Foundation

internal extension UIFont {
    
    internal static func system() -> UIFont {
        return UIFont.systemFont(ofSize: UIFont.systemFontSize)
    }
    
    internal var modifiers: FontModifier {
        var modifiers = FontModifier()
        let traits = self.fontDescriptor.symbolicTraits
        if traits.contains(.traitItalic) {
            modifiers.insert(.italic)
        }
        if traits.contains(.traitBold) {
            modifiers.insert(.bold)
        }
        return modifiers
    }
    
    internal func font(modified: FontModifier) -> UIFont {
        var traits = self.fontDescriptor.symbolicTraits
        modified.apply(traits: &traits)
        let newDescriptor = self.fontDescriptor.withSymbolicTraits(traits)!
        return UIFont.init(descriptor: newDescriptor, size: self.pointSize)
    }
    
    internal struct FontModifier: OptionSet {
        
        typealias RawValue = Int
        
        let rawValue: Int
        
        init(rawValue: RawValue) {
            self.rawValue = rawValue
        }
        
        internal static let bold = FontModifier.init(rawValue: 1 << 0)
        
        internal static let italic = FontModifier.init(rawValue: 1 << 1)
        
        internal func apply(traits: inout UIFontDescriptorSymbolicTraits) {
            print("\(self)")
            if self.contains(.bold) {
                traits.insert(.traitBold)
            }
            else {
                traits.remove(.traitBold)
            }
            
            if self.contains(.italic) {
                traits.insert(.traitItalic)
            }
            else {
                traits.remove(.traitItalic)
            }
        }
        
        internal var traits: UIFontDescriptorSymbolicTraits {
            var traits = UIFontDescriptorSymbolicTraits()
            if self.contains(.italic) {
                traits.insert(.traitItalic)
            }
            if self.contains(.bold) {
                traits.insert(.traitBold)
            }
            return traits
        }
    }
    
}
