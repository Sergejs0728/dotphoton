//
//  TestButton.swift
//  DotphotonConvert
//
//  Created by Christoph Clausen on 06.03.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Cocoa

@IBDesignable
class ButtonWithShadow: NSControl {
    
    @IBInspectable var fillColor: NSColor! = NSColor.Theme.buttonWhite { didSet { setup() } }
    @IBInspectable var textColor: NSColor! = NSColor.Theme.textDark { didSet { setup() } }
    @IBInspectable var text: String! = "Label" {
        didSet {
            textView.string = text
        }
    }
    
    @IBInspectable var fontSize: CGFloat = 16 {
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
        isEnabled = true
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
        
        layer?.cornerRadius = frame.height / 2
        layer?.backgroundColor = fillColor.cgColor
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowRadius = 9
        layer?.shadowOpacity = 0.05
        layer?.masksToBounds = false
    }
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        return NSPointInRect(point, frame) ? self : nil
    }
    
    override func mouseDown(with event: NSEvent) {
        if !isEnabled { return }
        super.mouseDown(with: event)
        let finalColor = NSColor.Theme.buttonHover.cgColor
        layer?.backgroundColor = finalColor
    }
    
    override func mouseUp(with event: NSEvent) {
        if !isEnabled { return }
        let finalColor = fillColor.cgColor
        layer?.backgroundColor = finalColor
        let point = convert(event.locationInWindow, from: nil)
        if bounds.contains(point), let action = action {
            NSApp.sendAction(action, to: target, from: self)
        }
    }
}
