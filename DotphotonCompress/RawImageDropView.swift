//
//  RawImageDropView.swift
//  DotphotonConvert
//
//  Created by Christoph Clausen on 02.02.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Cocoa

protocol RawImageDropDelegate {
    
    func dropHasEntered()
    func urlsDropped(_ urls: [URL])
    func dropHasEnded()
    
}

class RawImageDropView: NSView {
    
    var delegate: RawImageDropDelegate?
    let filteringOptions = [NSPasteboard.ReadingOptionKey.urlReadingFileURLsOnly: true]
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let pasteBoard = sender.draggingPasteboard
        
        var validCount = 0
        if let urls = pasteBoard.readObjects(forClasses: [NSURL.self], options: filteringOptions) as? [URL],
            urls.count > 0 {
            validCount = FileActions.canUrlsBeAdded(urls)[.ok]!
        }
        if validCount > 0 {
            sender.numberOfValidItemsForDrop = validCount
            delegate?.dropHasEntered()
            return .copy
        }
        return NSDragOperation()
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        // The drag has been released. Last chance to decide whether to accept the drag.
        // Note: Only relevant if draggingEntered already returned a valid drag operation.
        return true
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        delegate?.dropHasEnded()
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteBoard = sender.draggingPasteboard
        delegate?.dropHasEnded()
        if let urls = pasteBoard.readObjects(forClasses: [NSURL.self], options: filteringOptions) as? [URL],
            urls.count > 0 {
            delegate?.urlsDropped(urls)
            return true
        }
        return false
    }
}
