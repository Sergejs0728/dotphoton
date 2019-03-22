//
//  TestButton.swift
//  DotphotonConvert
//
//  Created by Christoph Clausen on 06.03.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Cocoa

@IBDesignable
class DialogOption: NSControl {
    
    @IBInspectable var fillColor: NSColor! = NSColor.Theme.windowBackground
    @IBInspectable var textColor: NSColor! = NSColor.Theme.textLight
    @IBInspectable var text: String! = "Label" {
        didSet {
            textView.string = text
            if let constraint = textHeightConstraint {
                constraint.constant = textHeight()
            }
        }
    }
    
    @IBInspectable var fontSize: CGFloat = 16
    
    private var trackingArea: NSTrackingArea?
    private var textHeightConstraint: NSLayoutConstraint?
    
    private let marginWidth: CGFloat = 24
    private let marginHeight: CGFloat = 16
    
    let textView = NSTextView()
    var labelFont: NSFont {
        get { return NSFont.systemFont(ofSize: fontSize)}
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
        translatesAutoresizingMaskIntoConstraints = false
        
        textView.removeConstraints(textView.constraints)
        textView.removeFromSuperview()
        
        textView.string = text
        textView.font = labelFont
        textView.textColor = textColor
        textView.alignCenter(nil)
        textView.drawsBackground = false
        textView.isEditable = false
        textView.isSelectable = false
        
        addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: marginWidth).isActive = true
        textView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -marginWidth).isActive = true
        textView.topAnchor.constraint(equalTo: topAnchor, constant: marginHeight).isActive = true
        textView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -marginHeight).isActive = true
        textHeightConstraint = textView.heightAnchor.constraint(equalToConstant: textHeight())
        textHeightConstraint!.isActive = true
        
        let hline = NSView(frame: CGRect(x: 0, y: 0, width: frame.width, height: 1))
        hline.wantsLayer = true
        hline.layerContentsRedrawPolicy = .onSetNeedsDisplay
        hline.layer?.backgroundColor = NSColor.Theme.border.cgColor
        addSubview(hline)
        hline.translatesAutoresizingMaskIntoConstraints = false
        hline.topAnchor.constraint(equalTo: topAnchor).isActive = true
        hline.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        hline.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        hline.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        layer?.backgroundColor = fillColor.cgColor
    }
    
    func textHeight() -> CGFloat {
        let maxSize = CGSize(constrainWidth: frame.width - 2 * marginWidth)
        let rect = textView.attributedString().boundingRect(with: maxSize, options: .usesLineFragmentOrigin)
        return rect.height
    }
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        return NSPointInRect(point, frame) ? self : nil
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea = self.trackingArea {
            self.removeTrackingArea(trackingArea)
        }
        
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways]
        let trackingArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
    
    override func mouseEntered(with event: NSEvent) {
        textView.textColor = NSColor.Theme.textDark
    }
    
    override func mouseExited(with event: NSEvent) {
        textView.textColor = textColor
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        let finalColor = NSColor.Theme.buttonHover.cgColor
        layer?.backgroundColor = finalColor
    }
    
    override func mouseUp(with event: NSEvent) {
        let finalColor = fillColor.cgColor
        layer?.backgroundColor = finalColor
        let point = convert(event.locationInWindow, from: nil)
        if bounds.contains(point), let action = action {
            NSApp.sendAction(action, to: target, from: self)
        }
    }
}
