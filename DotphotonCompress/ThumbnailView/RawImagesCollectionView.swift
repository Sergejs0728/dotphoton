//
//  RawImagesCollectionView.swift
//  DotphotonConvert
//
//  Created by Christoph Clausen on 19.06.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Cocoa
import DotphotonCompressBackend

class RawImagesCollectionView: NSCollectionView {

    let compressionManager = CompressionManager.shared
    let flowLayout = LeftFlowLayout()
    var itemSize = CGSize(width: 100, height: 100) {
        didSet {
            flowLayout.itemSize = itemSize
        }
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        setup()
    }
    
    fileprivate func setup() {
        dataSource = self
        
        flowLayout.itemSize = itemSize
        flowLayout.sectionInset = NSEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        flowLayout.minimumInteritemSpacing = 5.0
        flowLayout.minimumLineSpacing = 10.0
        
        collectionViewLayout = flowLayout
        
        registerForDraggedTypes([NSPasteboard.PasteboardType(kUTTypeFileURL as String)])
    }
    
    override func menu(for event: NSEvent) -> NSMenu? {
        let point = self.convert(event.locationInWindow, from:nil)
        if let clickedItemIndex = self.indexPathForItem(at: point),
            !selectionIndexPaths.contains(clickedItemIndex) {
            selectionIndexPaths = Set<IndexPath>([clickedItemIndex])
        }
        
        return super.menu(for: event)
    }
}

extension RawImagesCollectionView: NSCollectionViewDataSource {
    
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return compressionManager.pathCount
    }
    
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return compressionManager.numberOfFilesInPath(section)
    }
    
    func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {
        switch kind {
        case NSCollectionView.elementKindSectionHeader:
            let view = collectionView.makeSupplementaryView(ofKind: NSCollectionView.elementKindSectionHeader,
                                                            withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RawImagesCollectionViewHeader"),
                                                            for: indexPath) as! RawImagesCollectionViewHeader

            if let dirUrl = compressionManager.pathURL(at: indexPath.section) {
                view.setURL(dirUrl)
            }
            return view
        case NSCollectionView.elementKindSectionFooter:
            if indexPath.section == 0 { return NSView() }
            let view = collectionView.makeSupplementaryView(ofKind: NSCollectionView.elementKindSectionHeader,
                                                            withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RawImagesCollectionViewFooter"),
                                                            for: indexPath)
            return view
        // This works for macOS 10.12, and is even required to draw the selection rubber band. No longer
        // works for macOS 10.13, so the rubber band cannot be customized (e.g. color).
        case "NSCollectionElementKindSelectionRectIndicator":
            guard collectionView.numberOfSections > 0 else { return NSView() }
            fallthrough
        default:
            let view = collectionView.makeSupplementaryView(ofKind: kind, withIdentifier: NSUserInterfaceItemIdentifier(rawValue: kind), for: indexPath)
            return view
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RawImagesCollectionViewItem"), for: indexPath)
        guard let collectionViewItem = item as? RawImagesCollectionViewItem else {return item}
        
        let imageFile = compressionManager.rawImage(at: indexPath)
        collectionViewItem.imageFile = imageFile
        
        return item
        
    }
}
