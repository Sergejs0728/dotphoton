//
//  TestButton.swift
//  DotphotonConvert
//
//  Created by Christoph Clausen on 06.03.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Cocoa

@IBDesignable
class LabelButton: NSControl {
    
    @IBInspectable var textColor: NSColor! = NSColor.Theme.textLight { didSet { setup() } }
    @IBInspectable var text: String! = "Label" {
        didSet {
            textView.string = text
        }
    }
    
    @IBInspectable var fontSize: CGFloat = 13 {
        didSet {
            setup()
        }
    }
    
    let textView = NSTextView()
    var labelFont: NSFont {
        get { return NSFont.systemFont(ofSize: fontSize) }
    }

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
        
        textView.string = text
        textView.font = labelFont
        textView.textColor = textColor
        textView.alignCenter(nil)
        textView.drawsBackground = false
        textView.isEditable = false
        textView.isSelectable = false
        
        addSubview(textView)
        let stringSize = text.size(withAttributes: [NSAttributedString.Key.font : labelFont])
        textView.setFrameOrigin(NSPoint(x: 0.5, y: 0.5))
        textView.frame = CGRect(x: 0, y: (bounds.height - stringSize.height) / 2,
                                width: bounds.width, height: stringSize.height)
        
    }
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        return NSPointInRect(point, frame) ? self : nil
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        textView.textColor = NSColor.Theme.textDark
    }
    
    override func mouseUp(with event: NSEvent) {
        textView.textColor = textColor
        let point = convert(event.locationInWindow, from: nil)
        if bounds.contains(point), let action = action {
            NSApp.sendAction(action, to: target, from: self)
        }
    }
}
