//
//  PageControllerContainer.swift
//  DotphotonCompress
//
//  Created by Christoph Clausen on 25.07.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Cocoa
import DotphotonCompressBackend

class PageControllerContainer: NSViewController {
    
    enum mainWindowPage: String {
        case waitForDropPage
        case thumbnailPage
        case cameraSupportPage
    }
    
    @IBOutlet var pageController: NSPageController!
    var viewControllers: [NSViewController] = [NSViewController]()
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var pageControlButton: LabelButton!
    
    let pages: [mainWindowPage] = [.waitForDropPage, .thumbnailPage, .cameraSupportPage]
    
    var targetPage: mainWindowPage = .cameraSupportPage
    var buttonTexts = ["Camera packs ❯", "❮ Back"]
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize view controllers
        let waitForDropVC = WaitForDropViewController(nibName: "WaitForDropView", bundle: nil)
        waitForDropVC.view.autoresizingMask = [.height, .width]
        viewControllers.append(waitForDropVC)
        
        let thumbnailController = ThumbnailViewController(nibName: "ThumbnailViewController", bundle: nil)
        thumbnailController.view.autoresizingMask = [.height, .width]
        thumbnailController.container = self
        viewControllers.append(thumbnailController)
        
        let cameraSupportController = CameraSupportViewController(nibName: "CameraSupportViewController", bundle: nil)
        cameraSupportController.view.autoresizingMask = [.height, .width]
        viewControllers.append(cameraSupportController)
        
        pageController.view.wantsLayer = true
        pageController.arrangedObjects = pages.map { return $0.rawValue }
    }
    
    func gotoPage(_ page: mainWindowPage) {
        NSAnimationContext.runAnimationGroup({_ in
            self.pageController.animator().selectedIndex = pages.index(of: page)!
            
        },
        completionHandler: {self.pageController.completeTransition()})
    }
    
    @IBAction func labelClicked(_ sender: Any) {
        let oldPage = pages[pageController.selectedIndex]
        gotoPage(targetPage)
        
        pageControlButton.text = buttonTexts[targetPage == .cameraSupportPage ? 1 : 0]
        targetPage = oldPage
    }
    
    func updateStatusLabel(_ outcomes: [RawImageFileStore.AddFileResult: Int]) {
        let prefix = "ⓘ Psst, "
        var textPresent = false
        var label = ""
        if outcomes[.notRawImageFile]! > 0 {
            label += "some of the files were not raw, "
            textPresent = true
        }
        if outcomes[.duplicate]! > 0 {
            label += "there were some duplicates, "
            textPresent = true
        }
        if outcomes[.notSupported]! > 0 {
            if textPresent { label += "and " }
            label += "some files did not match your camera packages, "
            textPresent = true
        }
        if outcomes[.alreadyCompressed]! > 0 {
            if textPresent { label += "and " }
            label += "some files seem to already be compressed, "
            textPresent = true
        }
//        if textPresent {
//            statusLabel.stringValue = prefix + label + "so we skipped them."
//        } else {
//            statusLabel.stringValue = "We've added \(outcomes[.ok]!) of your cool photos!"
//        }
        
        // Set the title text
        statusLabel.stringValue = "Dotphoton Compress v1.0"
    }
    
    func updateStatusLabel(text: String) {
        statusLabel.stringValue = text
    }
}

extension PageControllerContainer: NSPageControllerDelegate {
    func pageController(_ pageController: NSPageController, identifierFor object: Any) -> NSPageController.ObjectIdentifier {
        return object as! NSPageController.ObjectIdentifier
    }
    
    func pageController(_ pageController: NSPageController, viewControllerForIdentifier identifier: NSPageController.ObjectIdentifier) -> NSViewController {
        if let page = mainWindowPage(rawValue: identifier),
            let index = pages.index(of: page) {
            let controller = viewControllers[index]
            return controller
        }
        return NSViewController()
    }
    
    func pageControllerDidEndLiveTransition(_ pageController: NSPageController) {
        pageController.completeTransition()
        pageController.selectedViewController!.view.autoresizingMask = [.height, .width]
    }
}
