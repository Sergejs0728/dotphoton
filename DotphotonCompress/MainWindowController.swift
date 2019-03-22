//
//  MainWindowController.swift
//  DotphotonConvert
//
//  Created by Christoph Clausen on 01.03.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Cocoa
import DotphotonCompressBackend

class MainWindowController: TitlelessWindowController {
    
    let compressionManager = CompressionManager.shared
    let autosaveName = "Main Window"
    var pager: PageControllerContainer? = nil
    
    var firstRun = true
    
    override func windowDidLoad() {
        super.windowDidLoad()
        pager = contentViewController as? PageControllerContainer
        
        // This apparently must be the last thing of the initialization
        windowFrameAutosaveName = autosaveName
    }
    
    func filesAdded(with results:[RawImageFileStore.AddFileResult: Int]) {
        if results[.ok]! > 0 {
            pager?.gotoPage(.thumbnailPage)
        }
        pager?.updateStatusLabel(results)
    }
}
