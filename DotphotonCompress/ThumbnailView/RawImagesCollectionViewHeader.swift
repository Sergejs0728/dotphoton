//
//  RawImagesCollectionViewHeader.swift
//  DotphotonConvert
//
//  Created by Christoph Clausen on 07.03.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Cocoa

class RawImagesCollectionViewHeader: NSView {

    @IBOutlet weak var titleLabel: NSTextField!
    
    func setURL(_ url: URL) {
        let dirName = url.lastPathComponent
        titleLabel.stringValue = "From " + dirName
    }
}
