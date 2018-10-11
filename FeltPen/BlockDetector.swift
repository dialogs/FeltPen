//
//  BlockDetector.swift
//  FeltPen
//
//  Created by Aleksei Gordeev on 26/09/2017.
//  Copyright © 2017 Aleksei Gordeev. All rights reserved.
//

import Foundation

public class BlockDetector: Detector {
	private let searchingItems: [Block.BlockType]
	public init(search: [Block.BlockType] = [.quote, .code]) {
		self.searchingItems = search
	}

	@discardableResult public func process(text: NSMutableAttributedString) throws -> DetectorResult {
        
        let string = text.string as NSString
        let wholeRange = NSRange.range(of: text.string)
        
        var stack: Stack = []
        var spots: [DetectorSpot] = []
        string.enumerateSubstrings(in: wholeRange, options: .byLines, using: { (substring, range, _, stop) in
            guard let line = substring, let detectedBlockType = self.blockForLine(line) else {
                return
            }
            let action = self.stackActionForBlock(detectedBlockType, stack: stack)
            switch action {
            case .nothing: break
            case .pop:
                let block = stack.removeLast()
                let spot = self.createSpot(block, end: NSMaxRange(range))
                spots.append(spot)
            case .push:
				stack.append(Block.init(type: detectedBlockType, start: range.location))
            }
        })
        
        spots.applySpots(text: text)
        
        return spots.count > 0 ? DetectorResult.attributesChange : DetectorResult.none
    }
    
    private func createSpot(_ block: Block, end: Int) -> DetectorSpot {
        let range = NSRange(location: block.start, length: end - block.start)
        let attributes = [block.type.attributeName : true]
        let spot = DetectorSpot.init(attributes, range: range)
        return spot
    }
    
    private typealias Stack = [Block]
    
    private enum StackAction: Int {
        case push
        case pop
        case nothing
    }
    
    private func stackActionForBlock(_ block: Block.BlockType, stack: Stack) -> StackAction {
        
        guard let lastBlock = stack.last else {
            return StackAction.push
        }
        
        if lastBlock.type == block {
            return .pop
        }
        else {
            if lastBlock.type == .quote && block == .code {
                return StackAction.push
            }
        }
        
        return StackAction.nothing
    }
    
    private func blockForLine(_ line: String) -> Block.BlockType? {
        if searchingItems.contains(.code) && line.hasPrefix("```") {
            return Block.BlockType.code
        }
        if searchingItems.contains(.quote) && line.hasPrefix(">") {
            return Block.BlockType.quote
        }
        return nil
    }
    
    private func isOpenBlock(block: Block.BlockType, stack: Stack) -> Bool {
        guard let currentBlock = stack.last else {
            return false
        }
        return currentBlock.type == block
    }
    
    public struct Block {
        
        var type: BlockType
        
        var start: Int
        
        public enum BlockType: Int {
            case code
            case quote
            
            var attributeName: DetectorAttributeName {
                switch self {
                case .code: return DetectorAttributeName.codeBlock
                case .quote: return DetectorAttributeName.quote
                }
            }
        }
        
    }
    
}
