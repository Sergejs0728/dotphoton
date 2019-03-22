//
//  DialogController.swift
//  DotphotonConvert
//
//  Created by Christoph Clausen on 13.04.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Cocoa

class DialogController: TitlelessWindowController {
    
    @IBOutlet weak var messageLabel: NSTextField!
    @IBOutlet weak var messageBox: NSBox!
    @IBOutlet weak var checkBoxBox: NSBox!
    @IBOutlet weak var checkBoxItem: NSButton!
    @IBOutlet weak var checkBoxHeight: NSLayoutConstraint!
    
    private var options = [DialogOption]()
    var checkBoxIsHidden = true {
        didSet {
            checkBoxHeight.constant = checkBoxIsHidden ? 0 : 50
        }
    }
    
    var checkBoxText: String = "" {
        didSet {
            if let mutableAttributedTitle = checkBoxItem.attributedTitle.mutableCopy() as? NSMutableAttributedString {
                mutableAttributedTitle.mutableString.setString(checkBoxText)
                checkBoxItem.attributedTitle = mutableAttributedTitle
            }
        }
    }
    
    var selectedOption: Int? = nil
    var topAnchor = NSLayoutYAxisAnchor()
    var bottomConstraint = NSLayoutConstraint()
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Color of check box
        if let mutableAttributedTitle = checkBoxItem.attributedTitle.mutableCopy() as? NSMutableAttributedString {
            mutableAttributedTitle.addAttribute(.foregroundColor, value: NSColor.Theme.textLight,
                                                range: NSRange(location: 0, length: mutableAttributedTitle.length))
            checkBoxItem.attributedTitle = mutableAttributedTitle
        }
        
        if let view = window?.contentView {
            topAnchor = checkBoxBox.bottomAnchor
            bottomConstraint = messageBox.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            bottomConstraint.isActive = true
        }
    }
    
    func windowWillClose(_ notification: Notification) {
        NSApp.stopModal()
    }
    
    func addDialogOption(_ labelText: String) {
        guard let view = window?.contentView else {
            print("Dialog: Cannot find view.")
            return
        }
        
        // Note: Doing the layout like this seems silly, but I could not get the StackView to display properly.
        let optionFrame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
        let option = DialogOption(frame: optionFrame)
        view.addSubview(option)
        
        // Set option text and action
        option.text = labelText
        option.action = #selector(dialogOptionClicked)
        options.append(option)
        
        // Set constraints
        option.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        option.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        option.topAnchor.constraint(equalTo: topAnchor).isActive = true
        
        // Be ready to accept next option
        topAnchor = option.bottomAnchor
        bottomConstraint.isActive = false
        bottomConstraint = option.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        bottomConstraint.isActive = true
    }
    
    @objc func dialogOptionClicked(_ sender: DialogOption) {
        selectedOption = options.index(of: sender)
        close()
    }
}
