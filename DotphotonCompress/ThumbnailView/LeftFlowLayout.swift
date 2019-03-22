//
//  LeftFlowLayout.swift
//  DotphotonConvert
//
//  Created by Christoph Clausen on 19.06.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Cocoa

// Found at https://stackoverflow.com/questions/36285720/nscollectionviewflowlayout-left-alignment
class LeftFlowLayout: NSCollectionViewFlowLayout {
    
    override func layoutAttributesForElements(in rect: CGRect) -> [NSCollectionViewLayoutAttributes] {
        
        let defaultAttributes = super.layoutAttributesForElements(in: rect)
        
        if defaultAttributes.isEmpty {
            // we rely on 0th element being present,
            // bail if missing (when there's no work to do anyway)
            return defaultAttributes
        }
        
        var leftAlignedAttributes = [NSCollectionViewLayoutAttributes]()
        
        var xCursor = self.sectionInset.left // left margin
        
        // if/when there is a new row, we want to start at left margin
        // the default FlowLayout will sometimes centre items,
        // i.e. new rows do not always start at the left edge
        
        var lastYPosition = defaultAttributes[0].frame.origin.y
        
        for attributes in defaultAttributes {
            let attributesCopy = attributes.copy() as! NSCollectionViewLayoutAttributes
            // Note: The next line should be "!=" and not ">", otherwise headers/footers stop working.
            if attributesCopy.frame.origin.y != lastYPosition {
                // we have changed line
                xCursor = self.sectionInset.left
                lastYPosition = attributesCopy.frame.origin.y
            }
            
            attributesCopy.frame.origin.x = xCursor
            // by using the minimumInterimitemSpacing we no we'll never go
            // beyond the right margin, so no further checks are required
            xCursor += attributesCopy.frame.size.width + minimumInteritemSpacing
            
            leftAlignedAttributes.append(attributesCopy)
        }
        return leftAlignedAttributes
    }
}
