//
//  AnswersHelper+ThumbnailViewController.swift
//  DotphotonCompress
//
//  Created by Christoph Clausen on 25.07.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Foundation
import Crashlytics

extension AnswersHelper {
    func logCompressionVCAddFilesClicked() {
        Answers.logCustomEvent(withName: "CompressionVCAddFilesClicked", customAttributes: nil)
    }
    
    func logCompressionVCRemoveSelection(count: Int) {
        let attr: [String: Any] = ["count": count]
        Answers.logCustomEvent(withName: "CompressionVCRemoveSelection", customAttributes: attr)
    }
    
    func logCompressionVCFileListEmpty() {
        Answers.logCustomEvent(withName: "CompressionVCFileListEmpty", customAttributes: nil)
    }
    
    func logCompressionVCStartButtonClicked(intention: StartButton.StartButtonState) {
        let attr: [String: Any] = ["intention": intention == .Running ? "run" : "stop"]
        Answers.logCustomEvent(withName: "CompressionVCStartButtonClicked", customAttributes: attr)
    }
    
    func logCompressionVCPreviewPanelShown() {
        Answers.logCustomEvent(withName: "CompressionVCPreviewPanelShown", customAttributes: nil)
    }
    
    func logCompressionVCPreviewPanelHidden() {
        Answers.logCustomEvent(withName: "CompressionVCPreviewPanelHidden", customAttributes: nil)
    }
    
    func logCompressionVCDragEntered() {
        Answers.logCustomEvent(withName: "CompressionVCDragEntered", customAttributes: nil)
    }
    
    func logCompressionVCAttemptingToAddFiles(count: Int) {
        let attr: [String: Any] = ["count": count]
        Answers.logCustomEvent(withName: "CompressionVCAttemptingToAddFiles", customAttributes: attr)
    }
    
    func logCompressionVCSelectedItems(count: Int) {
        let attr: [String: Any] = ["count": count]
        Answers.logCustomEvent(withName: "CompressionVCSelectedItems", customAttributes: attr)
    }
}
