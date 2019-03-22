//
//  CameraPacksViewController.swift
//  DotphotonCompress
//
//  Created by Christoph Clausen on 27.07.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Cocoa
import DotphotonCameraInfo

class CameraPacksViewController: NSViewController {
    
    @IBOutlet weak var collectionView: NSCollectionView!
    
    let cameraSupportManager = CameraSupportManagerFactory.get()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
        collectionView.reloadData()
    }
    
    fileprivate func setupCollectionView() {
        if let flowLayout = collectionView.collectionViewLayout as? ListFlowLayout {
            flowLayout.itemSize = NSSize(width: collectionView.bounds.width, height: 40)
            flowLayout.sectionInset = NSEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
            flowLayout.minimumInteritemSpacing = 10.0
            flowLayout.minimumLineSpacing = 0.0
        }
    }
    
}

extension CameraPacksViewController: NSCollectionViewDataSource {
    
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return cameraSupportManager.installedCameraPacks.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "CameraPackItem"), for: indexPath)
        guard let collectionViewItem = item as? CameraPackItem else { return item }
        
        let pack = cameraSupportManager.installedCameraPacks[indexPath.item]
        collectionViewItem.makerLabel.stringValue = pack.maker
        collectionViewItem.modelLabel.stringValue = pack.name
        
        return item
        
    }
}
