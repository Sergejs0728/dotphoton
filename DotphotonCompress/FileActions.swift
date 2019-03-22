//
//  AddFilesAction.swift
//  DotphotonConvert
//
//  Created by Christoph Clausen on 12.03.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Cocoa
import DotphotonCompressBackend
import DotphotonCameraInfo

class FileTransaction {
    
    var topLevelURLs = [URL]()
    var recursiveURLResults = [URL: RawImageFileStore.AddFileResult]()
    var resultSummary: [RawImageFileStore.AddFileResult: Int] = [.ok: 0, .notSupported: 0, .duplicate: 0, .notRawImageFile: 0, .alreadyCompressed: 0]
    
    func getRecursiveResults(_ urls: [URL])  -> [RawImageFileStore.AddFileResult: Int] {
        // Check if we already have a result prepared
        if urls == topLevelURLs { return resultSummary }
        
        // Otherwise, get the prospective results. Note that we should only update topLevelURLs once
        // everything is done, so that we do not get false results on the next call.
        for url in urls {
            if url.hasDirectoryPath {
                // Recursively add files from directory
                do {
                    let files = try FileManager.default.contentsOfDirectory(atPath: url.path)
                    let fileUrls = files.map({ (filePath) -> URL in
                        return url.appendingPathComponent(filePath)
                    })
                    let validUrls = fileUrls.filter({ (fileUrl) -> Bool in
                        return fileUrl.hasDirectoryPath || CameraSupportManagerFactory.get().supportedFileExtensions.contains(fileUrl.pathExtension.lowercased())
                    })
                    // We do not need to use the return value, since the result
                    // count is kept track of by an instance variable.
                    let _ = getRecursiveResults(validUrls)
                } catch {
                    print(error)
                }
            } else {
                let result = CompressionManager.shared.fileCanBeAdded(url)
                resultSummary[result]! += 1
                recursiveURLResults[url] = result
            }
        }
        topLevelURLs = urls
        AnswersHelper.shared.logResultOfAddFilesAttempt(resultSummary)
        return resultSummary
    }
    
    func commit() {
        CompressionManager.shared.addFiles(recursiveURLResults)
    }
}

class FileActions {
    
    static let compressionManager = CompressionManager.shared
    
    static var lastTransaction = FileTransaction()
    
    static func showOpenDialog(handler: @escaping ([URL]) -> Void) {
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose some raw images or directory";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = false;
        dialog.allowsMultipleSelection = true;
        dialog.allowedFileTypes        = [String](CameraSupportManagerFactory.get().supportedFileExtensions);
        
        dialog.begin { (response) in
            if response == .OK {
                handler(dialog.urls)
            } else {
                handler([URL]())
            }
        }
    }
    
    static func showOutputDirectoryDialog(handler: @escaping (URL?) -> Void) {
        let dialog = NSOpenPanel()
        
        dialog.title                   = "Choose output directory for compressed files"
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = false
        dialog.canChooseDirectories    = true
        dialog.canCreateDirectories    = true
        dialog.canChooseFiles          = false
        dialog.allowsMultipleSelection = false
        
        dialog.begin { (response) in
            if response == .OK {
                handler(dialog.urls[0])
            } else {
                // User clicked on "Cancel"
                handler(nil)
            }
        }
    }
    
    static func canUrlsBeAdded(_ urls: [URL]) -> [RawImageFileStore.AddFileResult: Int] {
        if lastTransaction.topLevelURLs == urls {
            return lastTransaction.getRecursiveResults(urls)
        } else {
            lastTransaction = FileTransaction()
            return lastTransaction.getRecursiveResults(urls)
        }
    }
    
    static func addUrls(_ urls: [URL]) -> [RawImageFileStore.AddFileResult: Int] {
        if lastTransaction.topLevelURLs != urls {
            fatalError("Trying to add URLs for which now transaction was prepared.")
        } else {
            lastTransaction.commit()
            let results = lastTransaction.resultSummary
            // Clear transaction
            lastTransaction = FileTransaction()
            return results
        }
        
    }
}
