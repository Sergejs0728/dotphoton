//
//  ThumbnailViewController.swift
//  DotphotonConvert
//
//  Created by Christoph Clausen on 01.03.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Cocoa
import Quartz
import DotphotonCompressBackend

class ThumbnailViewController: NSViewController {

    let compressionManager = CompressionManager.shared

    @IBOutlet weak var collectionScrollView: NSScrollView!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var collectionView: RawImagesCollectionView!
    @IBOutlet weak var fileInfoLabel: NSTextField!
    @IBOutlet weak var savingLabel: NSTextField!
    @IBOutlet weak var startButton: StartButton!
    @IBOutlet weak var gradientBox: GradientBox!
    @IBOutlet var contextMenu: RawImagesCollectionViewContextMenu!
    
    @objc dynamic var itemSize: Double = 100
    
    private var monitor = CompressionMonitor()
    var previewPanel = QLPreviewPanel.shared()
    
    var container: PageControllerContainer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        monitor.viewController = self
        compressionManager.delegates.append(monitor)
        
        configureKeyEvents()
        configureScrollView()
        
        contextMenu.collectionView = collectionView
        contextMenu.compressionViewController = self
        contextMenu.delegate = contextMenu
        
        let _ = compressionManager.fileWasAdded.addHandler(target: self, handler: ThumbnailViewController.fileWasAdded)
        let _ = compressionManager.fileListIsEmpty.addHandler(target: self, handler: ThumbnailViewController.fileListEmptied)
        let _ = compressionManager.sectionWasAdded.addHandler(target: self, handler: ThumbnailViewController.sectionWasAdded)
        let _ = compressionManager.bulkAdditions.addHandler(target: self, handler: ThumbnailViewController.bulkAdditions)
    }
    
    fileprivate func configureKeyEvents() {
        let arrowKeys = [NSEvent.SpecialKey.rightArrow.rawValue, NSEvent.SpecialKey.leftArrow.rawValue, NSEvent.SpecialKey.upArrow.rawValue, NSEvent.SpecialKey.downArrow.rawValue]
        let arrowCodes = arrowKeys.map {String(Character(UnicodeScalar($0)!))}
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { (event) in
            if event.charactersIgnoringModifiers == String(Character(UnicodeScalar(NSEvent.SpecialKey.delete.rawValue)!)) {
                if !self.collectionView.selectionIndexPaths.isEmpty {
                    self.deleteSelectedItems()
                }
                return nil
            } else if event.charactersIgnoringModifiers == " " {
                self.openPreviewPanel()
                return nil
            } else if arrowCodes.contains(event.charactersIgnoringModifiers!) {
                self.previewPanel?.reloadData()
            } else {
                switch event.modifierFlags.intersection(.deviceIndependentFlagsMask) {
                case [.command]:
                    if event.characters == "a" {
                        self.collectionView.selectAll(self)
                        return nil
                    }
                default:
                    break
                }
            }
            return event
        }
    }
    
    fileprivate func configureScrollView() {
        collectionScrollView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(scrollPositionChanged),
                                               name: NSView.boundsDidChangeNotification, object: collectionScrollView.contentView)
    }
    
    @IBAction func itemSizeChanged(_ sender: NSSlider) {
        let size = CGFloat(itemSize)
        collectionView.itemSize = NSSize(width: size, height: size)
    }
    
    @IBAction func addMoreClicked(_ sender: Any) {
        AnswersHelper.shared.logCompressionVCAddFilesClicked()
        FileActions.showOpenDialog { (urls) in
            AnswersHelper.shared.logCompressionVCAttemptingToAddFiles(count: urls.count)
            let results = FileActions.canUrlsBeAdded(urls)
            self.updateStatusLabel(results)
            DispatchQueue.global(qos: .userInitiated).async {
                let _ = FileActions.addUrls(urls)
            }
        }
    }
    
    func deleteSelectedItems() {
        let indexPaths = collectionView.selectionIndexPaths
        AnswersHelper.shared.logCompressionVCRemoveSelection(count: indexPaths.count)
        var sections = Set<Int>()
        for path in indexPaths {
            if let item = collectionView.item(at: path) as? RawImagesCollectionViewItem,
                let file = item.imageFile {
                compressionManager.remove(file)
                sections.insert(path.section)
            } else {
                print("Could not resolve index path.", path)
            }
        }
        
        for s in sections.sorted(by: >) {
            if(collectionView.numberOfItems(inSection: s) > 0) {
                sections.remove(s)
            }
        }
        
        collectionView.reloadData()
        // FixMe: The code below is supposed to update/animate the collectionview on demand, but
        // does not seem to take all deletions into account.
//        collectionView.animator().performBatchUpdates({
//            collectionView.deleteItems(at: indexPaths)
//            collectionView.deleteSections(IndexSet(sections))
//        }, completionHandler: nil)
        updateFileInfoLabel()
    }
    
    @objc func scrollPositionChanged() {
        guard let scroller = collectionScrollView.verticalScroller else { return }
        
        if scroller.floatValue == 1 {
            gradientBox.alphaValue = 0
        } else {
            gradientBox.alphaValue = 1
        }
    }
    
    fileprivate func fileWasAdded(_ file: RawImageFile) {
        // Attention: Using async here leads to crashes. Cause is unknown.
        DispatchQueue.main.sync {
            let indexPath = self.compressionManager.indexPath(of: file)!
            self.collectionView/*.animator()*/.insertItems(at: Set<IndexPath>([indexPath]))
            self.updateFileInfoLabel()
            self.startButton.isEnabled = true
            
        }
    }
    
    fileprivate func sectionWasAdded(_ url: URL) {
        DispatchQueue.main.sync {
            if let section = self.compressionManager.sectionIndex(of: url) {
                self.collectionView.insertSections(IndexSet(integer: section))
            }
        }
    }
    
    fileprivate func bulkAdditions(_ additions: (IndexSet, Set<IndexPath>)) {
        DispatchQueue.main.async {
            self.collectionView.performBatchUpdates({
                self.collectionView.insertSections(additions.0)
                self.collectionView.insertItems(at: additions.1)
            }, completionHandler: nil)
            self.updateFileInfoLabel()
            self.startButton.isEnabled = self.compressionManager.totalFileCount > 0
        }
    }
    
    fileprivate func fileListEmptied(_: ()) {
        AnswersHelper.shared.logCompressionVCFileListEmpty()
        DispatchQueue.main.async {
            if let controller = NSApp.mainWindow?.contentViewController as? PageControllerContainer {
                controller.gotoPage(.waitForDropPage)
            }
        }
    }
    
    fileprivate func updateFileInfoLabel() {
        let selected = collectionView.selectionIndexPaths.count
        let total = compressionManager.totalFileCount
        var sizeMB: Float = 0
        
        if selected > 0 {
            fileInfoLabel.stringValue = "\(selected) of \(total) selected,"
            
            for path in collectionView.selectionIndexPaths {
                if let file = compressionManager.rawImage(at: path) {
                    sizeMB += file.fileSizeMB
                }
            }
        } else {
            fileInfoLabel.stringValue = "\(total) file\(total > 1 ? "s" : ""),"
            
            for file in compressionManager.allFiles {
                sizeMB += file.fileSizeMB
            }
        }
        
        fileInfoLabel.stringValue += String(format: " %.0f MB", sizeMB)
        
        savingLabel.stringValue = String(format: "You are about to free up %.0f MB", 7*sizeMB/8)
    }
    
    func updateStatusLabel(_ outcomes: [RawImageFileStore.AddFileResult: Int]) {
        container?.updateStatusLabel(outcomes)
    }
    
    func updateStatusLabel(text: String) {
        container?.updateStatusLabel(text: text)
    }
    
    @IBAction func startButtonClicked(_ sender: Any) {
        // Note: startButton.state is the one after clicking
        AnswersHelper.shared.logCompressionVCStartButtonClicked(intention: startButton.state)
        if startButton.state == .Running {
            FileActions.showOutputDirectoryDialog { url in
                self.compressionManager.outputDirURL = url
                if url != nil {
                    self.compressionManager.startCompression(for: self.collectionView.selectionIndexPaths)
                } else {
                    self.startButton.stop()
                }
            }
        } else {
            compressionManager.stopCompression()
        }
    }
    
    override func acceptsPreviewPanelControl(_ panel: QLPreviewPanel!) -> Bool {
        return true
    }
    
    override func beginPreviewPanelControl(_ panel: QLPreviewPanel!) {
        previewPanel?.delegate = self
        previewPanel?.dataSource = self
        AnswersHelper.shared.logCompressionVCPreviewPanelShown()
    }
    
    override func endPreviewPanelControl(_ panel: QLPreviewPanel!) {
        // This is called when the preview panel is hidden. We don't need to
        // do anything, I think.
        AnswersHelper.shared.logCompressionVCPreviewPanelHidden()
    }
    
    func openPreviewPanel() {
        if !self.collectionView.selectionIndexPaths.isEmpty {
            if (QLPreviewPanel.sharedPreviewPanelExists() && self.previewPanel!.isVisible) {
                self.previewPanel?.orderOut(nil)
            } else {
                self.previewPanel?.makeKeyAndOrderFront(nil)
            }
        }
    }
}


extension ThumbnailViewController: NSCollectionViewDelegate {
    
    func collectionView(_ collectionView: NSCollectionView, validateDrop draggingInfo: NSDraggingInfo, proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>, dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>) -> NSDragOperation {
        
        AnswersHelper.shared.logCompressionVCDragEntered()
        
        // Accept drop if at least one of the files is supported
        let pasteBoard = draggingInfo.draggingPasteboard
        let filteringOptions = [NSPasteboard.ReadingOptionKey.urlReadingFileURLsOnly: true]
        
        var validCount = 0
        if let urls = pasteBoard.readObjects(forClasses: [NSURL.self], options: filteringOptions) as? [URL],
            urls.count > 0 {
            validCount = FileActions.canUrlsBeAdded(urls)[.ok]!
        }
        if validCount > 0 {
            draggingInfo.numberOfValidItemsForDrop = validCount
            return .copy
        }
        return NSDragOperation()
    }
    
    func collectionView(_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, indexPath: IndexPath, dropOperation: NSCollectionView.DropOperation) -> Bool {
        let pasteBoard = draggingInfo.draggingPasteboard
        let filteringOptions = [NSPasteboard.ReadingOptionKey.urlReadingFileURLsOnly: true]
        
        if let urls = pasteBoard.readObjects(forClasses: [NSURL.self], options: filteringOptions) as? [URL],
            urls.count > 0 {
            
            AnswersHelper.shared.logCompressionVCAttemptingToAddFiles(count: urls.count)
            let results = FileActions.canUrlsBeAdded(urls)
            
            DispatchQueue.global(qos: .userInitiated).async {
                let _ = FileActions.addUrls(urls)
            }
            updateStatusLabel(results)
            return true
        }
        return false
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        AnswersHelper.shared.logCompressionVCSelectedItems(count: indexPaths.count)
        updateFileInfoLabel()
        if self.previewPanel!.isVisible { self.previewPanel?.reloadData() }
    }
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        updateFileInfoLabel()
        if self.previewPanel!.isVisible { self.previewPanel?.reloadData() }
    }
}

extension ThumbnailViewController: NSCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> NSSize {
        return NSSize(width: 1000, height: 40)
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, referenceSizeForFooterInSection section: Int) -> NSSize {
        return NSSize(width: 1000, height: 1)
    }
}

extension ThumbnailViewController: QLPreviewPanelDataSource {
    
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        return collectionView.selectionIndexPaths.count
    }
    
    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        guard let cv = collectionView else { return RawImagesCollectionViewItem() }
        let path = cv.selectionIndexPaths[cv.selectionIndexPaths.index(cv.selectionIndexPaths.startIndex, offsetBy: index)]
        let item = cv.item(at: path) as! RawImagesCollectionViewItem
        return item
    }
}

extension ThumbnailViewController: QLPreviewPanelDelegate {
    
    func previewPanel(_ panel: QLPreviewPanel!, transitionImageFor item: QLPreviewItem!, contentRect: UnsafeMutablePointer<NSRect>!) -> Any! {
        if let imageItem = item as? RawImagesCollectionViewItem {
            return imageItem.imageFile?.thumbnail
        }
        return nil
    }
    
    func previewPanel(_ panel: QLPreviewPanel!, handle event: NSEvent!) -> Bool {
        // redirect all key down events to the table view
        if event.type == .keyDown {
            collectionView?.keyDown(with: event)
            return true
        }
        return false;
    }
}
