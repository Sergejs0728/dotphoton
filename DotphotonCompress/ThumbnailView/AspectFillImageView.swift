//
//  AspectFillImageView.swift
//  DotphotonConvert
//
//  Created by Christoph Clausen on 02.02.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Cocoa

class AspectFillImageView : NSImageView {
    
    override var image: NSImage? {
        set {
            self.layer = CALayer()
            self.layer?.contentsGravity = CALayerContentsGravity.resizeAspectFill
            self.layer?.contents = newValue
            self.wantsLayer = true
            
            self.layer?.displayIfNeeded()
        }
        
        get {
            return super.image
        }
    }
}
