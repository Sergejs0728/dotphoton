//
//  CustomSliderCell.swift
//  DotphotonConvert
//
//  Created by Christoph Clausen on 19.06.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Cocoa

class CustomSliderCell: NSSliderCell {
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func drawBar(inside aRect: NSRect, flipped: Bool) {
        var rect = aRect
        rect.size.height = CGFloat(5)
        let barRadius = CGFloat(2.5)
        let bg = NSBezierPath(roundedRect: rect, xRadius: barRadius, yRadius: barRadius)
        NSColor.Theme.textLight.setFill()
        bg.fill()
    }
    
}
