//
//  DNGConverterDownloadViewController.swift
//  DotphotonCompress
//
//  Created by Christoph Clausen on 25.07.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Cocoa
import Crashlytics
import DotphotonCompressBackend

class DNGConverterDownloadViewController: NSViewController {
    
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
    
    @IBOutlet weak var downloadButton: ButtonWithShadow!
    @IBOutlet weak var downloadProgress: NSProgressIndicator!
    @IBOutlet weak var downloadStatus: NSTextField!
    @IBOutlet weak var installButton: ButtonWithShadow!
    @IBOutlet weak var installProgress: NSProgressIndicator!
    @IBOutlet weak var installStatus: NSTextField!
    @IBOutlet weak var verifyButton: ButtonWithShadow!
    
    var completionEvent = Event<Void>()
    
    
    // For downloading
    let downloadURL = URL(string: "http://download.adobe.com/pub/adobe/dng/mac/DNGConverter_10_4.dmg")!
    var downloadTask: URLSessionDownloadTask?
    lazy var downloadsSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    var temporaryLocation: URL?
    var resumeData: Data?
    var downloadStartTime: Date = Date()
    
    // For monitoring the installer application
    let installerURL = URL(fileURLWithPath: "/Volumes/DNGConverter_10_4/DNGConverter_10_4.pkg")
    var installerApplication: NSRunningApplication?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        installButton.isEnabled = false
        verifyButton.isEnabled = false
    }
    
    @IBAction func downloadClicked(_ sender: Any) {
        switch state {
        case .ready:
            startDownload()
        case .downloading:
            cancelDownload()
        case .downloadFailed:
            fallthrough
        case .stopped:
            startDownload()
        default:
            print("Default")
        }
    }
    
    @IBAction func installClicked(_ sender: Any) {
        if state == .installationFailed {
            startInstallation()
        }
    }
    
    func stateChanged() {
        // Adapt UI according to new state.
        switch state {
        case .downloading:
            downloadButton.text = "■"
        case .downloadFailed:
            downloadStatus.stringValue = "Failed"
            downloadButton.text = "↻"
        case .stopped:
            downloadButton.text = "►"
        case .downloaded:
            downloadButton.text = "✓"
            downloadButton.isEnabled = false
            startInstallation()
            downloadStatus.stringValue = "Done"
            installStatus.stringValue = "Launching"
        case .installing:
            installButton.text = "⋯"
            installButton.isEnabled = false
            installStatus.stringValue = "In progress"
            installProgress.isIndeterminate = true
            installProgress.startAnimation(nil)
        case .installed:
            installStatus.stringValue = "Done"
            installProgress.stopAnimation(nil)
            installButton.text = "✓"
            if DNGConverterWrapper() != nil {
                verifyButton.text = "✓"
                AnswersHelper.shared.logInstallDNGConverterInstallationCompleted()
            } else {
                verifyButton.text = "╳"
                state = .installationFailed
            }
            completionEvent.notify(())
        case .installationFailed:
            AnswersHelper.shared.logInstallDNGConverterInstallationFailed()
            showInstallationFailedMessage()
            installStatus.stringValue = "Failed"
            installButton.text = "↻"
            installButton.isEnabled = true
        default:
            // Do nothing
            break
        }
    }
    
    // MARK: - Installation process
    fileprivate func startDownload() {
        if let data = resumeData {
            downloadTask = downloadsSession.downloadTask(withResumeData: data)
            AnswersHelper.shared.logInstallDNGConverterDownloadResumed()
        } else {
            AnswersHelper.shared.logInstallDNGConverterDownloadStarted()
            downloadTask = downloadsSession.downloadTask(with: downloadURL)
        }
        downloadStartTime = Date()
        downloadTask!.resume()
        state = .downloading
    }
    
    fileprivate func cancelDownload() {
        AnswersHelper.shared.logInstallDNGConverterDownloadStopped()
        downloadTask?.cancel(byProducingResumeData: { (data) in
            self.resumeData = data
        })
        state = .stopped
    }
    
    fileprivate func mountDiskImage() {
        guard let path = temporaryLocation?.path,
            FileManager.default.fileExists(atPath: path) else {
                print("Cannot mount disk image: file not found!")
                return
        }
        
        let process = Process()
        process.launchPath = "/usr/bin/hdiutil"
        
        process.arguments = ["attach", path]
        process.launch()
        process.waitUntilExit()
    }
    
    fileprivate func startInstallation() {
        AnswersHelper.shared.logInstallDNGConverterInstallationStarted()
        mountDiskImage()
        // Mounting may take some time, so poll for existance of installer
        DispatchQueue.main.async {
            let timer = Timer(timeInterval: 1, target: self, selector: #selector(self.checkForInstaller), userInfo: nil, repeats: true)
            RunLoop.current.add(timer, forMode: RunLoop.Mode.default)
        }
    }
    
    func cleanUp() {
        // Unmount disk image
        let process = Process()
        process.launchPath = "/usr/bin/hdiutil"
        
        process.arguments = ["detach", "/Volumes/DNGConverter_10_4"]
        process.launch()
        process.waitUntilExit()
        
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
            RunLoop.current.add(timer, forMode: RunLoop.Mode.default)
        }
    }
    
    @objc fileprivate func monitorInstaller(_ timer: Timer) {
        if installerApplication?.isTerminated ?? true {
            // Stop timer
            timer.invalidate()
            state = .installed
        }
    }
    
    // MARK: - Dialogs
    func showInstallationFailedMessage() {
        // Force loading of window
        let dialog = DialogController(windowNibName: "DialogController")
        let _ = dialog.window
        dialog.messageLabel.stringValue = "It looks like the installation failed or was cancelled: DNG Converter still cannot be found in the applications folder."
        
        dialog.checkBoxIsHidden = true
        
        dialog.addDialogOption("Close")
        
        NSApp.runModal(for: dialog.window!)
    }
    
    func showDownloadErrorMessage(_ error: Error) {
        let dialog = DialogController(windowNibName: "DialogController")
        
        // Force loading of window
        let _ = dialog.window
        dialog.messageLabel.stringValue = error.localizedDescription
        
        dialog.checkBoxIsHidden = true
        
        dialog.addDialogOption("Close")
        
        NSApp.runModal(for: dialog.window!)
    }
}

extension DNGConverterDownloadViewController: URLSessionDownloadDelegate, URLSessionTaskDelegate, URLSessionDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Copy file to temporary directory when download has completed
        let filename = downloadURL.lastPathComponent
        temporaryLocation = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
        if !FileManager.default.fileExists(atPath: temporaryLocation!.path) {
            do {
                try FileManager.default.copyItem(at: location, to: temporaryLocation!)
            } catch {
                let err = error as NSError
                let newErr = err.addItemsToUserInfo(newUserInfo: ["Trigger": "CopyDNGConverterAfterDownload"])
                Crashlytics.sharedInstance().recordError(newErr)
            }
        }
        state = .downloaded
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        DispatchQueue.main.async {
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            self.downloadProgress.doubleValue = 100.0 * progress
            let elapsed = Date().timeIntervalSince(self.downloadStartTime)
            let total = elapsed / progress
            let eta = total - elapsed
            self.downloadStatus.stringValue = String(format:"%d:%02d", Int(eta) / 60, Int(eta) % 60)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error, (error as NSError).code != -999 {
            Crashlytics.sharedInstance().recordError(error)
            DispatchQueue.main.async {
                self.showDownloadErrorMessage(error)
                self.state = .downloadFailed
            }
        }
    }
}
