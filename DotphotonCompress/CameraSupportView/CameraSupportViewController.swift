//
//  CameraSupportViewController.swift
//  DotphotonCompress
//
//  Created by Christoph Clausen on 25.07.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Cocoa
import DotphotonCompressBackend

class CameraSupportViewController: NSViewController {
    
    @IBOutlet var downloadViewController: DNGConverterDownloadViewController!
    @IBOutlet var cameraPackViewController: CameraPacksViewController!
    
    @IBOutlet weak var nativeFileSupportBox: NSBox!
    @IBOutlet weak var nativeFileSupportHeader: NSTextField!
    @IBOutlet weak var nativeFileSupportLine: NSBox!
    @IBOutlet weak var nativeFileSupportBoxTop: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.Theme.windowBackground.cgColor
        
        let _ = downloadViewController.completionEvent.addHandler(target: self, handler: CameraSupportViewController.hideNativeFileSupportBox)
        if DNGConverterWrapper() != nil { nativeFileSupportBoxTop.constant = -self.nativeFileSupportBox.frame.height }
        
        addCameraPackViewController()
    }
    
    fileprivate func addCameraPackViewController() {
        let packView = cameraPackViewController.view
        packView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(packView)
        packView.topAnchor.constraint(equalTo: nativeFileSupportBox.bottomAnchor).isActive = true
        packView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        packView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        packView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }
    
    @IBAction func installClicked(_ sender: Any) {
        AnswersHelper.shared.logInstallDNGConverterClicked()
        
        let downloadView = downloadViewController.view
        downloadView.translatesAutoresizingMaskIntoConstraints = false
        nativeFileSupportBox.addSubview(downloadView)
        downloadView.widthAnchor.constraint(equalTo: nativeFileSupportBox.widthAnchor).isActive = true
        downloadView.topAnchor.constraint(equalTo: nativeFileSupportHeader.bottomAnchor, constant: 10).isActive = true
        downloadView.bottomAnchor.constraint(equalTo: nativeFileSupportLine.topAnchor, constant: -5).isActive = true
        let leadingAnchor = downloadView.leadingAnchor.constraint(equalTo: nativeFileSupportBox.leadingAnchor, constant: nativeFileSupportBox.frame.width)
        leadingAnchor.isActive = true
        leadingAnchor.animator().constant = 0
    }
    
    func hideNativeFileSupportBox(_: ()) {
        downloadViewController.cleanUp()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current.completionHandler = { self.nativeFileSupportBox.isHidden = true }
            self.nativeFileSupportBoxTop.animator().constant = -self.nativeFileSupportBox.frame.height
            NSAnimationContext.endGrouping()
        }
        
    }
}
