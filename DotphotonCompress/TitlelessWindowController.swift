//
//  TitlelessWindowController.swift
//  DotphotonCompress
//
//  Created by Christoph Clausen on 24.07.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Cocoa

class TitlelessWindowController: NSWindowController {

    let titlebarHeight = 20
    let buttonMargin:CGFloat = 15
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Make window content fill whole window (no titlebar)
        window?.titleVisibility = .hidden
        window?.titlebarAppearsTransparent = true
        window?.styleMask.insert(.fullSizeContentView)
        
        // For button alignment, insert ghost view that regulates titlebar height
        let vc = NSTitlebarAccessoryViewController()
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 10, height: titlebarHeight))
        vc.view = view
        window?.insertTitlebarAccessoryViewController(vc, at: 0)
        
        // Restore button position after resizing via delegate
        window?.delegate = self
    }
    
    fileprivate func setupButtons() {
        let standardButtons = [NSWindow.ButtonType.closeButton,
                               NSWindow.ButtonType.miniaturizeButton,
                               NSWindow.ButtonType.zoomButton]
        
        for (i, buttonType) in standardButtons.enumerated() {
            let button = window!.standardWindowButton(buttonType)!
            var frame = button.frame
            
            frame.origin.y = button.superview!.frame.height / 2 - button.frame.height / 2
            frame.origin.x = buttonMargin + CGFloat(i) * (frame.width + 6)
            button.frame = frame
        }
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        setupButtons()
    }
}

extension TitlelessWindowController: NSWindowDelegate {
    func windowDidResize(_ notification: Notification) {
        setupButtons()
    }
}
