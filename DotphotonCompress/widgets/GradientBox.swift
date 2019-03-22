//
//  GradientView.swift
//  DotphotonConvert
//
//  Created by Christoph Clausen on 12.03.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Cocoa

class GradientBox: NSBox {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        setup()
    }
    
    fileprivate func setup() {
        wantsLayer = true
        layerContentsRedrawPolicy = .onSetNeedsDisplay
        
        let gradient = CAGradientLayer()
        //gradient.frame = layer!.bounds
        layer = gradient
        let bgColor = NSColor.Theme.windowBackground
        gradient.colors = [bgColor.cgColor, bgColor.withAlphaComponent(0).cgColor]
        //layer?.addSublayer(gradient)
    }
}
