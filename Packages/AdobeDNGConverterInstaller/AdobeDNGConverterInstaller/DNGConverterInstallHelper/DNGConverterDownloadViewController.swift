//
//  DNGConverterDownloadViewController.swift
//  DotphotonCompress
//
//  Created by Christoph Clausen on 25.07.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Foundation
import Cocoa

public class DNGConverterDownloadViewController: NSViewController {
    
    enum State {
        case ready
        case downloading
        case stopped
        case downloaded
        case installing
        case installed
        case downloadFailed
        case installationFailed
    }
    
    var state: State = .ready {
        didSet { DispatchQueue.main.async { self.stateChanged() } }
    }
    
    @IBOutlet weak var progress: NSProgressIndicator!
    @IBOutlet weak var status: NSTextField!
    @IBOutlet weak var button: NSButton!
    
    // For downloading
    let downloadURL = URL(string: "http://download.adobe.com/pub/adobe/dng/mac/DNGConverter_10_5.dmg")!
    var downloadTask: URLSessionDownloadTask?
    lazy var downloadsSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    var temporaryLocation: URL?
    var resumeData: Data?
    
    // For monitoring the installer application
    let installerURL = URL(fileURLWithPath: "/Volumes/DNGConverter_10_5/DNGConverter_10_5.pkg")
    var installerApplication: NSRunningApplication?
    
    @objc public var completionHandler: (() -> ())?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        button.isEnabled = false
    }
    
    @IBAction func buttonClicked(_ sender: Any) {
        switch state {
        case .downloading:
            cancelDownload()
        case .downloadFailed:
            fallthrough
        case .stopped:
            startDownload()
        case .installationFailed:
            startInstallation()
        default:
            print("Default")
        }
    }
    
    func stateChanged() {
        // Adapt UI according to new state.
        switch state {
        case .downloading:
            button.title = "Cancel"
            button.isEnabled = true
            status.stringValue = "Downloading..."
        case .stopped:
            button.title = "Resume"
            status.stringValue = "The download was cancelled."
        case .downloadFailed:
            status.stringValue = "Failed"
            button.title = "Retry"
        case .downloaded:
            startInstallation()
            status.stringValue = "Launching installer..."
        case .installing:
            button.title = "⋯"
            button.isEnabled = false
            status.stringValue = "Waiting for installation to complete..."
            progress.isIndeterminate = true
            progress.startAnimation(nil)
        case .installed:
            status.stringValue = "Installation complete."
            progress.stopAnimation(nil)
            button.title = "Done"
            if isDNGConverterInstalled() {
                if let handler = completionHandler {
                    handler()
                }
                cleanUp()
            } else {
                state = .installationFailed
            }
        case .installationFailed:
            showInstallationFailedMessage()
            status.stringValue = "Installation failed."
            button.title = "Retry"
            button.isEnabled = true
        default:
            // Do nothing
            break
        }
    }
    
    // MARK: - Installation process
    @objc public func startDownload() {
        if let data = resumeData {
            downloadTask = downloadsSession.downloadTask(withResumeData: data)
            NSLog("Resuming previous download...")
            //AnswersHelper.shared.logInstallDNGConverterDownloadResumed()
        } else {
            //AnswersHelper.shared.logInstallDNGConverterDownloadStarted()
            downloadTask = downloadsSession.downloadTask(with: downloadURL)
            NSLog("Starting download...")
        }
        downloadTask!.resume()
        state = .downloading
    }
    
    @objc public func isDNGConverterInstalled() -> Bool {
        return NSWorkspace.shared.fullPath(forApplication: "Adobe DNG Converter") != nil
    }
    
    fileprivate func cancelDownload() {
        //AnswersHelper.shared.logInstallDNGConverterDownloadStopped()
        downloadTask?.cancel(byProducingResumeData: { (data) in
            self.resumeData = data
        })
        state = .stopped
    }
    
    fileprivate func mountDiskImage() {
        guard let path = temporaryLocation?.path,
            FileManager.default.fileExists(atPath: path) else {
                NSLog("Cannot mount disk image: file not found!")
                return
        }
        
        let process = Process()
        process.launchPath = "/usr/bin/hdiutil"
        
        process.arguments = ["attach", path]
        process.launch()
        process.waitUntilExit()
    }
    
    fileprivate func startInstallation() {
        //AnswersHelper.shared.logInstallDNGConverterInstallationStarted()
        mountDiskImage()
        // Mounting may take some time, so poll for existance of installer
        DispatchQueue.main.async {
            let timer = Timer(timeInterval: 1, target: self, selector: #selector(self.checkForInstaller), userInfo: nil, repeats: true)
            RunLoop.current.add(timer, forMode: RunLoopMode.defaultRunLoopMode)
        }
    }
    
    func cleanUp() {
        // Todo: Unmount disk image. It seems the installer blocks the image for a while after finishing installation.
        // let process = Process()
        // process.launchPath = "/usr/bin/hdiutil"
        
        // process.arguments = ["unmount", "/Volumes/DNGConverter_10_5"]
        // process.launch()
        // process.waitUntilExit()
        
        // Delete temporary file
        if let path = temporaryLocation?.path,
            FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.removeItem(at: temporaryLocation!)
        }
    }
    
    // MARK: - Timer functions
    @objc fileprivate func checkForInstaller(_ timer: Timer) {
        if FileManager.default.fileExists(atPath: installerURL.path) {
            self.installerApplication = try? NSWorkspace.shared.open(installerURL, options: [], configuration: [:])
            timer.invalidate()
            
            // Change state
            self.state = .installing
            
            // Monitor installer
            let timer = Timer(timeInterval: 1, target: self, selector: #selector(self.monitorInstaller), userInfo: nil, repeats: true)
            RunLoop.current.add(timer, forMode: RunLoopMode.defaultRunLoopMode)
        }
    }
    
    @objc fileprivate func monitorInstaller(_ timer: Timer) {
        let windowList = CGWindowListCopyWindowInfo(.excludeDesktopElements, kCGNullWindowID) as! Array<[NSString:Any]>;
        var adobeInstallerRunning = false
        for window in windowList {
            if let pid = installerApplication?.processIdentifier,
                let win_pid = window[kCGWindowOwnerPID] as? pid_t,
                win_pid == pid,
                let name = window[kCGWindowName] as? String,
                name.contains("Adobe DNG Converter")
            {
                adobeInstallerRunning = true
                break
            }
        }
        
        if adobeInstallerRunning == false {
            // Stop timer
            NSLog("Adobe Installer seems finished.")
            timer.invalidate()
            state = .installed
        }
    }
    
    // MARK: - Dialogs
    func showInstallationFailedMessage() {
        NSLog("Installation failed dialoge...")
        
        let dialog = NSAlert()
        dialog.messageText = "It looks like the installation failed or was cancelled: DNG Converter still cannot be found in the applications folder."
        dialog.addButton(withTitle: "OK")
        dialog.beginSheetModal(for: view.window!, completionHandler: nil)
    }
    
    func showDownloadErrorMessage(_ error: Error) {
        NSLog("Download error dialoge...")
        
        let dialog = NSAlert(error: error)
        dialog.beginSheetModal(for: view.window!, completionHandler: nil)
    }
}

extension DNGConverterDownloadViewController: URLSessionDownloadDelegate, URLSessionTaskDelegate, URLSessionDelegate {
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Copy file to temporary directory when download has completed
        let filename = downloadURL.lastPathComponent
        temporaryLocation = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)

        do {
            try FileManager.default.moveItem(at: location, to: temporaryLocation!)
        } catch {
            NSLog("Error moving downloaded file: %@", error.localizedDescription)
        }
        
        state = .downloaded
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        DispatchQueue.main.async {
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            self.progress.doubleValue = 100.0 * progress
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error, (error as NSError).code != -999 {
            DispatchQueue.main.async {
                self.showDownloadErrorMessage(error)
                self.state = .downloadFailed
            }
        }
    }
}
