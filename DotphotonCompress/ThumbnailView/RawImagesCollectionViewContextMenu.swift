//
//  RawImagesCollectionViewContextMenu.swift
//  DotphotonConvert
//
//  Created by Christoph Clausen on 19.06.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Cocoa

class RawImagesCollectionViewContextMenu: NSMenu {
    
    var collectionView: RawImagesCollectionView?
    var compressionViewController: ThumbnailViewController?
    var openWithAppUrls = [String: URL]()
    
    @IBOutlet weak var compressToItem: NSMenuItem!
    @IBOutlet weak var showInFinderItem: NSMenuItem!
    @IBOutlet weak var quickLookItem: NSMenuItem!
    @IBOutlet weak var removeItem: NSMenuItem!
    @IBOutlet weak var openWithMenu: NSMenu!
    
    @IBAction func compressTo(_ sender: Any) {
        compressionViewController?.startButton.animateShrink(compressionViewController!.startButton.startBox)
        compressionViewController?.startButton.start()
        compressionViewController?.startButtonClicked(sender)
    }
    
    @IBAction func showInFinder(_ sender: Any) {
        // Todo: Get index of item under cursor
        guard let collectionView = self.collectionView,
            let indexPath = collectionView.selectionIndexPaths.first,
            let item = collectionView.item(at: indexPath) as? RawImagesCollectionViewItem,
            let file = item.imageFile else { return }
        
        NSWorkspace.shared.selectFile(file.url.path, inFileViewerRootedAtPath: file.url.deletingLastPathComponent().path)
    }
    
    @IBAction func quickLook(_ sender: Any) {
        compressionViewController?.openPreviewPanel()
    }
    
    @IBAction func openExternally(_ sender: NSMenuItem) {
        guard let cv = self.collectionView else { return }
        for path in cv.selectionIndexPaths {
            let item = cv.item(at: path) as! RawImagesCollectionViewItem
            NSWorkspace.shared.openFile(item.imageFile!.url.path, withApplication: openWithAppUrls[sender.title]!.path)
        }
    }
    
    @IBAction func remove(_ sender: Any) {
        compressionViewController?.deleteSelectedItems()
    }
}

extension RawImagesCollectionViewContextMenu: NSMenuDelegate {
    
    private func addOpenWithItem(_ appUrl: URL, isDefault: Bool = false) {
        let name = appUrl.lastPathComponent
        let item = NSMenuItem(title: name, action: #selector(openExternally), keyEquivalent: String())
        item.image = NSWorkspace.shared.icon(forFile: appUrl.path)
        // Images are too big by default
        item.image?.size = CGSize(width: 16, height: 16)
        if isDefault {
            item.title = item.title + " (default)"
        }
        item.target = self
        openWithMenu.addItem(item)
        openWithAppUrls[item.title] = appUrl
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        guard let cv = collectionView else { return }
        let noSelection = cv.selectionIndexes.count == 0
        
        removeItem.isHidden = noSelection
        showInFinderItem.isHidden = noSelection
        
        if !noSelection {
            let item = cv.item(at: cv.selectionIndexPaths.first!) as! RawImagesCollectionViewItem
            let defaultAppUrl = LSCopyDefaultApplicationURLForURL(item.imageFile!.url as CFURL, .all, nil)?.takeRetainedValue()
            let appUrls = LSCopyApplicationURLsForURL(item.imageFile!.url as CFURL, .all)?.takeRetainedValue() as NSArray?
            
            // Populate menu
            openWithMenu.removeAllItems()
            openWithAppUrls.removeAll()
            
            if let defaultUrl = defaultAppUrl {
                addOpenWithItem(defaultUrl as URL, isDefault: true)
                openWithMenu.addItem(NSMenuItem.separator())
            }
            if let urls = appUrls {
                for appUrl in urls {
                    let url = appUrl as! CFURL
                    if url == defaultAppUrl || (url as URL).absoluteString.contains("DotphotonCompress") { continue }
                    addOpenWithItem(url as URL)
                }
            }
        }
    }
}

