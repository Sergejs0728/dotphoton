//
//  AppDelegate.swift
//  DotphotonConvert
//
//  Created by Christoph Clausen on 02.02.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Cocoa
import Fabric
import Crashlytics
import DotphotonCompressBackend
import DotphotonCameraInfo

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Next line is recommended by Crashlytics
        UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions": true])
                                                 // "NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints": true])
        
        CameraSupportManagerFactory.get().setDecryptor(DotphotonSigning.shared()!.restore)
        Fabric.with([Crashlytics.self])
        configureFileLogger()
        AnswersHelper.shared.logAppLaunched()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        AnswersHelper.shared.logAppTerminated()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        let urls = filenames.parallelMap(maxParallelism: nil) { (filename) -> URL in
            return URL(fileURLWithPath: filename)
        }
        let results = FileActions.canUrlsBeAdded(urls)
        if let windowController = NSApplication.shared.mainWindow?.windowController as? MainWindowController {
            windowController.filesAdded(with: results)
        }
        let _ = FileActions.addUrls(urls)
    }
    
    fileprivate func configureFileLogger() {
        let dir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory,
                                                      FileManager.SearchPathDomainMask.userDomainMask, true)
        let logFileUrl = URL(fileURLWithPath: dir.first!, isDirectory: true).appendingPathComponent("log.txt")
        if let logger = CompressionFileLogger(url: logFileUrl) {
            print("Logging to:", logFileUrl)
            CompressionManager.shared.delegates.append(logger)
        } else {
            print("WARNING: Could not open logfile at \(logFileUrl)")
        }
    }
}

