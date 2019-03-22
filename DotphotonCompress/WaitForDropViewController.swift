//
//  ViewControllerWaitingForDrop.swift
//  DotphotonConvert
//
//  Created by Christoph Clausen on 01.03.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Cocoa

class WaitForDropViewController: NSViewController {

    @IBOutlet weak var browseButton: ButtonWithShadow!
    let dropView = AcceptDropView(frame: NSRect.zero)
    var mainWindowController: MainWindowController?
    
    @IBOutlet weak var openBrowseButton: NSButton!
    
    override func awakeFromNib() {
        if self.view.layer != nil {
            let color : CGColor = CGColor(red: 0.0, green: 0, blue: 0, alpha: 1.0)
            self.view.layer?.backgroundColor = color
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.registerForDraggedTypes([NSPasteboard.PasteboardType(kUTTypeFileURL as String)])
        (view as! RawImageDropView).delegate = self
        configureDropView()
        
        // set background color of browse button
        self.openBrowseButton.layer?.backgroundColor = CGColor.clear
    }
    
    override func viewWillAppear() {
        mainWindowController = NSApp.mainWindow?.windowController as? MainWindowController
    }
    
    override var nibName: NSNib.Name? { return "WaitForDropView" }
    
    fileprivate func configureDropView() {
        view.addSubview(dropView)
        dropView.isHidden = true
        dropView.translatesAutoresizingMaskIntoConstraints = false
        
        dropView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        dropView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        dropView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        dropView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    @IBAction func openFilesClicked(_ sender: Any) {
        AnswersHelper.shared.logWaitForDropAddFilesClicked()
        FileActions.showOpenDialog(handler: addUrlsIfPossible)
    }
    
    // Open the file browser
    @IBAction func openFileSelector(_ sender: Any) {
        AnswersHelper.shared.logWaitForDropAddFilesClicked()
        FileActions.showOpenDialog(handler: addUrlsIfPossible)
    }
    
    
    fileprivate func addUrlsIfPossible(_ urls: [URL]) {
        let results = FileActions.canUrlsBeAdded(urls)
        
        if let mainVC = self.mainWindowController {
            mainVC.filesAdded(with: results)
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let _ = FileActions.addUrls(urls)
        }
    }
}

extension WaitForDropViewController: RawImageDropDelegate {
    func dropHasEntered() {
        dropView.isHidden = false
    }
    
    func urlsDropped(_ urls: [URL]) {
        addUrlsIfPossible(urls)
    }
    
    func dropHasEnded() {
        dropView.isHidden = true
    }
}
