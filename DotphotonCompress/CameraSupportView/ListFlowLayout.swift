//
//  ListFlowLayout.swift
//  DotphotonCompress
//
//  Created by Christoph Clausen on 22.10.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//
import Cocoa

class ListFlowLayout: NSCollectionViewFlowLayout {
    
    override func layoutAttributesForElements(in rect: CGRect) -> [NSCollectionViewLayoutAttributes] {
        
        let defaultAttributes = super.layoutAttributesForElements(in: rect)
        
        if defaultAttributes.isEmpty {
            // we rely on 0th element being present,
            // bail if missing (when there's no work to do anyway)
            return defaultAttributes
        }
        
        var alignedAttributes = [NSCollectionViewLayoutAttributes]()
        
        for attributes in defaultAttributes {
            let attributesCopy = attributes.copy() as! NSCollectionViewLayoutAttributes
            // Note: The next line should be "!=" and not ">", otherwise headers/footers stop working.
            
            attributesCopy.frame.origin.x = self.sectionInset.left
            attributesCopy.frame.size.width = self.collectionView!.frame.width - self.sectionInset.left - self.sectionInset.right
            
            alignedAttributes.append(attributesCopy)
        }
        return alignedAttributes
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: NSRect) -> Bool {
        return true
    }
}
