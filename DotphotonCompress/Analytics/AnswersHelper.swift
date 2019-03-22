//
//  AnswersHelper.swift
//  DotphotonConvert
//
//  Created by Christoph Clausen on 18.07.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Foundation
import Fabric
import Crashlytics
import DotphotonCompressBackend

class AnswersHelper {
    
    let uuid: String
    static let shared = AnswersHelper()
    
    private init() {
        uuid = UUID().uuidString
    }
    
    // MARK: - Application Events:
    
    func logAppLaunched() {
        let attr: [String: Any] = ["uuid": uuid]
        Answers.logCustomEvent(withName: "ApplicationLaunched", customAttributes: attr)
    }
    
    func logAppTerminated() {
        let attr: [String: Any] = ["uuid": uuid]
        Answers.logCustomEvent(withName: "ApplicationTerminated", customAttributes: attr)
    }
    
    // MARK: - WaitForDropViewController
    
    func logWaitForDropAddFilesClicked() {
        Answers.logCustomEvent(withName: "WaitForDropAddFilesClicked", customAttributes: nil)
    }
    
    func logWaitForDropDragEntered() {
        Answers.logCustomEvent(withName: "WaitForDropDragEntered", customAttributes: nil)
    }
    
    func logWaitForDropAttemptingToAddFiles(count: Int) {
        let attr: [String: Any] = ["count": count]
        Answers.logCustomEvent(withName: "WaitForDropAttemptingToAddFiles", customAttributes: attr)
    }
    
    // MARK: - Raw File Handling
    func logResultOfAddFilesAttempt(_ result: [RawImageFileStore.AddFileResult: Int]) {
        let attr: [String: Any] = ["ok": result[.ok]!, "notRaw": result[.notRawImageFile]!,
                                   "duplicate": result[.duplicate]!, "notSupported": result[.notSupported]!,
                                   "alreadyCompressed": result[.alreadyCompressed]!]
        Answers.logCustomEvent(withName: "ResultOfAddFilesAttempt", customAttributes: attr)
    }
    
    func logRawImageFileInit(_ file:RawImageFile) {
        let ext = file.url.pathExtension
        let size = file.fileSizeMB
        let supported = file.supportsDotphotonCompression
        var maker = ""
        var model = ""
        var iso: Double = 0
        if let meta = file.metaData {
            maker = meta.cameraMaker ?? ""
            model = meta.cameraModel ?? ""
            iso = meta.ISO ?? 0
        }
        
        let attr: [String: Any] = ["extension": ext, "fileSize": size, "maker": maker,
                                   "model": model, "iso": iso, "supported": supported]
        Answers.logCustomEvent(withName: "RawImageFileInit", customAttributes: attr)
    }
}

extension AnswersHelper: CompressionDelegate {
    func compressionWasStarted() {
        Answers.logCustomEvent(withName: "CompressionStarted", customAttributes: nil)
    }
    
    func fileWillBeCompressed(file: RawImageFile) {
        // Do nothing
    }
    
    func fileWasCompressed(file: RawImageFile, success: Bool) {
        let ext = file.url.pathExtension
        let size = file.fileSizeMB
        var maker = ""
        var model = ""
        var iso: Double = 0
        if let meta = file.metaData {
            maker = meta.cameraMaker ?? ""
            model = meta.cameraModel ?? ""
            iso = meta.ISO ?? 0
        }
        var compressedSize: Float = 0
        if let path = file.compressedDestination?.path,
            let attributes = try? FileManager.default.attributesOfItem(atPath: path) as NSDictionary {
            let size = attributes.fileSize()
            compressedSize = Float(size) / 1024 / 1024
        }
        
        let attr: [String: Any] = ["extension": ext, "fileSize": size, "maker": maker,
                                   "model": model, "iso": iso, "success": success,
                                   "compressionFactor": size/compressedSize]
        Answers.logCustomEvent(withName: "FileWasCompressed", customAttributes: attr)
    }
    
    func compressionWasCompleted(wasCancelled: Bool) {
        let attr: [String: Any] = ["cancelled": wasCancelled]
        Answers.logCustomEvent(withName: "CompressionCompleted", customAttributes: attr)
    }
    
    func message(file: RawImageFile, text: String) {
        let ext = file.url.pathExtension
        let size = file.fileSizeMB
        var maker = ""
        var model = ""
        var iso: Double = 0
        if let meta = file.metaData {
            maker = meta.cameraMaker ?? ""
            model = meta.cameraModel ?? ""
            iso = meta.ISO ?? 0
        }
        
        let attr: [String: Any] = ["extension": ext, "fileSize": size, "maker": maker,
                                   "model": model, "iso": iso, "message": text]
        Answers.logCustomEvent(withName: "FileCompressionMessage", customAttributes: attr)
    }
    
    
}
