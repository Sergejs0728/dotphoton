//
//  ViewAcceptDrop.swift
//  DotphotonConvert
//
//  Created by Christoph Clausen on 01.03.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Cocoa

@IBDesignable
class AcceptDropView: NSView, NibLoadableView {
    
    @IBOutlet var view: NSView!
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        setupFromNib()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupFromNib()
    }
    
}
