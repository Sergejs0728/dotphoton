//
//  CompressionProgressDelegate.swift
//  DotphotonConvert
//
//  Created by Christoph Clausen on 05.04.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Cocoa
import DotphotonCompressBackend

class CompressionMonitor: CompressionDelegate {
    
    let compressionManager = CompressionManager.shared
    var viewController: ThumbnailViewController?
    
    private var total = 0
    private var completed = 0
    private var failed = 0
    let semaphore = DispatchSemaphore(value: 1)
    
    func compressionWasStarted() {
        DuplicateDialogHandler.handleInputDuplicates()
        DuplicateDialogHandler.handleOutputConflicts()
        
        total = compressionManager.taskCount
        completed = 0
        failed = 0
    }
    
    func fileWillBeCompressed(file: RawImageFile) {
        // Do nothing
    }
    
    func fileWasCompressed(file: RawImageFile, success: Bool) {
        // This can possibly be done by several threads simultaneously
        semaphore.wait()
        completed += 1
        if success {
            self.compressionManager.remove(file)
        } else {
            failed += 1
        }
        semaphore.signal()
        let progress = CGFloat(completed) / CGFloat(total)
        
        // Update progress and remove file from view
        DispatchQueue.main.async {
            if let vc = self.viewController {
                vc.startButton.progress = progress
            }
        }
    }
    
    func compressionWasCompleted(wasCancelled: Bool) {
        if wasCancelled {
            DispatchQueue.main.async {
                self.viewController?.startButton.stop()
            }
        }
        
        if failed > 0 {
            DispatchQueue.main.async {
                self.viewController?.updateStatusLabel(text: "\(self.failed) file\(self.failed > 1 ? "s" : "") could not be compressed.")
            }
        } else {
            DispatchQueue.main.async {
                self.viewController?.updateStatusLabel(text: "Successfully compressed \(self.completed) file\(self.completed > 1 ? "s" : "")")
            }
        }
    }
    
    func message(file: RawImageFile, text: String) {
        DispatchQueue.main.async {
            self.viewController?.updateStatusLabel(text: "\(file.fileName) - " + text)
        }
    }
}
