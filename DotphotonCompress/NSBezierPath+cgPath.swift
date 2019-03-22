//
//  NSBezierPath+cgPath.swift
//  DotphotonConvert
//
//  Created by Christoph Clausen on 03.04.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Cocoa

public extension NSBezierPath {
    
    public var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        for i in 0 ..< self.elementCount {
            let type = self.element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo: path.move(to: CGPoint(x: points[0].x, y: points[0].y) )
            case .lineTo: path.addLine(to: CGPoint(x: points[0].x, y: points[0].y) )
            case .curveTo: path.addCurve(to: CGPoint(x: points[2].x, y: points[2].y),
                                         control1: CGPoint(x: points[0].x, y: points[0].y),
                                         control2: CGPoint(x: points[1].x, y: points[1].y) )
            case .closePath: path.closeSubpath()
            }
        }
        return path
    }
}
