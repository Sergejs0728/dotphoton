//
//  AddMoreButton.swift
//  DotphotonConvert
//
//  Created by Christoph Clausen on 12.03.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Cocoa

@IBDesignable
class AddMoreButton: NSControl, NibLoadableView {

    @IBOutlet var view: NSView!
    @IBOutlet weak var crossView: NSView!
    @IBOutlet weak var labelText: NSTextField!
    
    private let hoverLayer = CALayer()
    private let bgColor = NSColor.Theme.windowBackground
    private var trackingArea: NSTrackingArea?
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        setupFromNib()
        setup()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupFromNib()
        setup()
    }
    
    fileprivate func setup() {
        wantsLayer = true
        layerContentsRedrawPolicy = .onSetNeedsDisplay
        hoverLayer.frame = layer!.bounds
        layer?.addSublayer(hoverLayer)
        
        hoverLayer.cornerRadius = 10
        hoverLayer.backgroundColor = bgColor.cgColor
        layer?.backgroundColor = bgColor.cgColor
    }
    
    override func mouseEntered(with event: NSEvent) {
        let color = NSColor.Theme.textDark
        NSAnimationContext.runAnimationGroup({ (context) in
            context.duration = 3
            for subview in crossView.subviews {
                subview.animator().layer?.backgroundColor = color.cgColor
            }
            labelText.animator().textColor = color
        }, completionHandler: nil)
    }
    
    override func mouseExited(with event: NSEvent) {
        let color = NSColor.Theme.textLight
        for subview in crossView.subviews {
            subview.layer?.backgroundColor = color.cgColor
        }
        labelText.textColor = color
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
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        return NSPointInRect(point, frame) ? self : nil
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        let finalColor = NSColor.Theme.buttonHover.cgColor
        hoverLayer.backgroundColor = finalColor
    }
    
    override func mouseUp(with event: NSEvent) {
        let finalColor = bgColor.cgColor
        hoverLayer.backgroundColor = finalColor
        let point = convert(event.locationInWindow, from: nil)
        if bounds.contains(point), let action = action {
            NSApp.sendAction(action, to: target, from: self)
        }
    }
    
}
