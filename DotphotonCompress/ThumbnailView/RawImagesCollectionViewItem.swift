//
//  RawImagesCollectionViewItem.swift
//  DotphotonConvert
//
//  Created by Christoph Clausen on 02.02.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Cocoa
import Quartz
import DotphotonCompressBackend

class RawImagesCollectionViewItem: NSCollectionViewItem {
    
    @IBOutlet weak var highlightFrame: NSBox!
    @IBOutlet var frameWidth: NSLayoutConstraint!
    @IBOutlet var frameHeight: NSLayoutConstraint!
    
    private var handler: Disposable?
    private var completionHandler: Disposable?
    
    var imageFile: RawImageFile? {
        didSet {
            guard isViewLoaded else { return }
            self.imageView?.image = #imageLiteral(resourceName: "Placeholder")
            if let imageFile = imageFile {
                self.view.toolTip = imageFile.url.path
                imageFile.fetchThumbnail { (thumb) in
                    self.imageView?.image = thumb
                }
                handler?.dispose()
                handler = imageFile.compressionStarted.addHandler(target: self, handler: RawImagesCollectionViewItem.markInProgress)
                imageView?.subviews.removeAll()
                
                completionHandler?.dispose()
                completionHandler = imageFile.compressionCompleted.addHandler(target: self, handler: RawImagesCollectionViewItem.markComplete)
            } else {
                imageView?.image = nil
            }
        }
    }
    
    override var isSelected: Bool {
        didSet {
            updateFrame()
        }
    }
    
    override var highlightState: NSCollectionViewItem.HighlightState {
        didSet {
            updateFrame()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.layerContentsRedrawPolicy = .onSetNeedsDisplay
        imageView?.unregisterDraggedTypes()
    }
    
    func updateFrame() {
        guard let imageView = imageView, let image = imageView.image else { return }
        
        let showFrame = (isSelected && highlightState != .forDeselection) || highlightState == .forSelection
        highlightFrame.isHidden = !showFrame
        
        let iSize = image.size
        let ratio = iSize.width / iSize.height
        let cst:CGFloat = 6
        if ratio > 1 {
            frameWidth.isActive = false
            frameWidth = NSLayoutConstraint(item: highlightFrame, attribute: .width, relatedBy: .equal,
                                            toItem: imageView, attribute: .width, multiplier: 1, constant: cst)
            frameWidth.isActive = true
            
            frameHeight.isActive = false
            frameHeight = NSLayoutConstraint(item: highlightFrame, attribute: .height, relatedBy: .equal,
                                             toItem: imageView, attribute: .height, multiplier: 1/ratio, constant: cst)
            frameHeight.isActive = true
        } else {
            frameWidth.isActive = false
            frameWidth = NSLayoutConstraint(item: highlightFrame, attribute: .width, relatedBy: .equal,
                                            toItem: imageView, attribute: .width, multiplier: ratio, constant: cst)
            frameWidth.isActive = true
            
            frameHeight.isActive = false
            frameHeight = NSLayoutConstraint(item: highlightFrame, attribute: .height, relatedBy: .equal,
                                             toItem: imageView, attribute: .height, multiplier: 1, constant: cst)
            frameHeight.isActive = true
        }
    }
    
    func markInProgress(_: ()) {
        DispatchQueue.main.async {
            guard let imageView = self.imageView, let image = imageView.image else { return }
            let ratio = image.size.width / image.size.height
            
            // CIFilter causes glitches in custom views. Do not apply for now.
            // (Although I don't know why)
            /*
            let blurView = NSView()
            blurView.wantsLayer = true
            blurView.layerContentsRedrawPolicy = .onSetNeedsDisplay
            blurView.frame = imageView.bounds
            blurView.isHidden = true
            
            let gauss = CIFilter(name: "CIGaussianBlur")!
            gauss.setDefaults()
            gauss.setValue(2, forKey: kCIInputRadiusKey)
            blurView.backgroundFilters = [gauss]

            self.imageView!.addSubview(blurView)
            */
            
            let progressView = NSImageView()
            progressView.image = NSImage(named: "ProgressWatch")
            progressView.wantsLayer = true
            progressView.layer?.backgroundColor = NSColor.Theme.pauseCircle.withAlphaComponent(0.5).cgColor
            self.imageView!.addSubview(progressView)
            
            for view in [progressView] {//}, blurView] {
                view.translatesAutoresizingMaskIntoConstraints = false
                view.centerXAnchor.constraint(equalTo: imageView.centerXAnchor).isActive = true
                view.centerYAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true
                if ratio > 1 {
                    view.widthAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
                    view.heightAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: 1/ratio).isActive = true
                } else {
                    view.heightAnchor.constraint(equalTo: imageView.heightAnchor).isActive = true
                    view.widthAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: ratio).isActive = true
                }
            }
        }
    }
    
    func markComplete(success: Bool) {
        if !success {
            DispatchQueue.main.async {
                self.imageView?.subviews.removeAll()
            }
            return
        }
        DispatchQueue.main.async {
            if let cv = self.collectionView, let index = cv.indexPath(for: self) {
                let isLast = cv.numberOfItems(inSection: index.section) == 1
                if isLast {
                    cv.deleteSections(IndexSet(integer: index.section))
                } else {
                    let indexSet: Set<IndexPath> = Set([index])
                    cv.deleteItems(at: indexSet)
                }
            }
        }
    }
}

extension RawImagesCollectionViewItem: QLPreviewItem {
    var previewItemURL: URL! {
        return self.imageFile!.url
    }
}
