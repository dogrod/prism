//
//  ReceiptPath.swift
//  Prism
//
//  Created by Brian Zhu on 2025/12/29.
//

import UIKit

/// Helper to generate sawtooth/jagged edge paths for receipt-style views
enum ReceiptPath {
    
    /// Generate a path with a sawtooth bottom edge
    /// - Parameters:
    ///   - rect: The bounding rectangle
    ///   - toothWidth: Width of each tooth (default: 10)
    ///   - toothHeight: Height of each tooth (default: 8)
    /// - Returns: A UIBezierPath with straight top and jagged bottom
    static func jaggedPath(
        for rect: CGRect,
        toothWidth: CGFloat = 10,
        toothHeight: CGFloat = 8
    ) -> UIBezierPath {
        let path = UIBezierPath()
        
        // Start at top-left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        
        // Top edge (straight)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        
        // Right edge (straight)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - toothHeight))
        
        // Bottom edge (sawtooth pattern)
        let numberOfTeeth = Int(rect.width / toothWidth)
        let actualToothWidth = rect.width / CGFloat(numberOfTeeth)
        
        var currentX = rect.maxX
        
        for i in 0..<numberOfTeeth {
            let isEven = i % 2 == 0
            
            if isEven {
                // Go down to tooth point
                path.addLine(to: CGPoint(x: currentX - actualToothWidth / 2, y: rect.maxY))
            } else {
                // Go up from tooth point
                path.addLine(to: CGPoint(x: currentX - actualToothWidth / 2, y: rect.maxY - toothHeight))
            }
            
            currentX -= actualToothWidth / 2
            
            if isEven {
                // Go up from tooth point
                path.addLine(to: CGPoint(x: currentX - actualToothWidth / 2, y: rect.maxY - toothHeight))
            } else {
                // Go down to tooth point
                path.addLine(to: CGPoint(x: currentX - actualToothWidth / 2, y: rect.maxY))
            }
            
            currentX -= actualToothWidth / 2
        }
        
        // Left edge (straight back up)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        
        path.close()
        return path
    }
    
    /// Generate a simple zigzag path for the bottom edge
    static func zigzagPath(
        for rect: CGRect,
        toothWidth: CGFloat = 12,
        toothHeight: CGFloat = 6
    ) -> UIBezierPath {
        let path = UIBezierPath()
        
        // Start at top-left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        
        // Top edge
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        
        // Right edge
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - toothHeight))
        
        // Bottom zigzag
        let numberOfTeeth = Int(rect.width / toothWidth)
        let actualToothWidth = rect.width / CGFloat(numberOfTeeth)
        
        var currentX = rect.maxX
        var goingDown = true
        
        while currentX > rect.minX {
            let nextX = max(currentX - actualToothWidth, rect.minX)
            let y = goingDown ? rect.maxY : rect.maxY - toothHeight
            path.addLine(to: CGPoint(x: nextX, y: y))
            currentX = nextX
            goingDown.toggle()
        }
        
        // Left edge back up
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        
        path.close()
        return path
    }
}
