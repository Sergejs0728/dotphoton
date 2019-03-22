//
//  DuplicateDialogHandler.swift
//  DotphotonConvert
//
//  Created by Christoph Clausen on 17.04.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Cocoa
import DotphotonCompressBackend

class DuplicateDialogHandler {
    
    static let compressionManager = CompressionManager.shared
    
    static func handleInputDuplicates() {
        // Let user take action for duplicate input files
        let handler = DuplicateHandler(queue: compressionManager.compressionQueue)
        var duplicateMap = handler.checkForInputDuplicates()
        repeat {
            let duplicateNodes = duplicateMap.values.joined()
            if !duplicateNodes.isEmpty {
                let dialog = DialogController(windowNibName: "DialogController")
                // Force loading of window
                let _ = dialog.window
                let node = duplicateNodes.first!
                let fileName = node.value.inURL.lastPathComponent
                dialog.messageLabel.stringValue = """
                Compression of \(fileName) will result in the same file name as
                another file. What shall we do?
                """
                if duplicateNodes.count > 1 {
                    dialog.checkBoxIsHidden = false
                    dialog.checkBoxText = "Apply to all \(duplicateNodes.count) files."
                } else {
                    dialog.checkBoxIsHidden = true
                }
                
                dialog.addDialogOption("Skip file")
                dialog.addDialogOption("Rename compressed file")
                dialog.addDialogOption("Cancel compression")
                NSApp.runModal(for: dialog.window!)
                let forAll = dialog.checkBoxItem.state == .on
                switch dialog.selectedOption {
                case .some(0):
                    handler.resolveInputDuplicate(node: node, in: &duplicateMap, by: .skipping, applyToAll: forAll)
                case .some(1):
                    handler.resolveInputDuplicate(node: node, in: &duplicateMap, by: .renaming, applyToAll: forAll)
                case .some(2):
                    fallthrough
                default:
                    // Cancel compression
                    compressionManager.stopCompression()
                    return
                }
            }
            // We cannot check against duplicatNodes, because it is not updated by the handler!
        } while( !duplicateMap.values.joined().isEmpty )
    }
    
    static func handleOutputConflicts() {
        // Let user take action for duplicate input files
        let handler = DuplicateHandler(queue: compressionManager.compressionQueue)
        guard let outDir = compressionManager.outputDirURL else {
            preconditionFailure("No output directory specified.")
        }
        
        var conflicts = handler.checkForOutputConflicts(for: outDir)
        repeat {
            if !conflicts.isEmpty {
                let dialog = DialogController(windowNibName: "DialogController")
                // Force loading of window
                let _ = dialog.window
                let node = conflicts.first!
                let fileName = node.value.nonNilOutputFileName
                dialog.messageLabel.stringValue = """
                A file named \(fileName + ".p.dng") already exists in this location. What shall we do?
                """
                if conflicts.count > 1 {
                    dialog.checkBoxIsHidden = false
                    dialog.checkBoxText = "Apply to all \(conflicts.count) files."
                } else {
                    dialog.checkBoxIsHidden = true
                }
                
                dialog.addDialogOption("Skip file")
                dialog.addDialogOption("Rename compressed file")
                dialog.addDialogOption("Overwrite existing file")
                dialog.addDialogOption("Cancel compression")
                NSApp.runModal(for: dialog.window!)
                let forAll = dialog.checkBoxItem.state == .on
                switch dialog.selectedOption {
                case .some(0):
                    handler.resolveOutputConflicts(node: node, in: &conflicts, for: outDir, by: .skipping, applyToAll: forAll)
                case .some(1):
                    handler.resolveOutputConflicts(node: node, in: &conflicts, for: outDir, by: .renaming, applyToAll: forAll)
                case .some(2):
                    handler.resolveOutputConflicts(node: node, in: &conflicts, for: outDir, by: .overwriting, applyToAll: forAll)
                case .some(3):
                    fallthrough
                default:
                    // Cancel compression
                    compressionManager.stopCompression()
                    return
                }
            }
        // We cannot check against duplicatNodes, because it is not updated by the handler!
        } while( !conflicts.isEmpty )
    }
}

