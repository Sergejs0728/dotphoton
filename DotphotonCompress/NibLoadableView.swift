//
//  DropView.swift
//  DotphotonConvert
//
//  Created by Christoph Clausen on 02.02.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Cocoa

protocol NibLoadableView {
    var view: NSView! { get set }
}

extension NibLoadableView where Self: NSView {
    
    func setupFromNib() {
        self.wantsLayer = true
        self.layer?.backgroundColor = CGColor(gray: 0.9, alpha: 0.9)
        
        let myName = type(of: self).className().components(separatedBy: ".").last!
        if let nib = NSNib(nibNamed: myName, bundle: Bundle(for: type(of: self))) {
            
            
            /// You must instantiate a new view from the NIB attached to you as the owner,
            /// this will replace the one originally built at app start-up
            nib.instantiate(withOwner: self, topLevelObjects: nil)
            
            /// Now create a new array of constraints by copying the old ones.
            /// We replace ourself as either the first or second item as appropriate in place of topView.
            /// We grab these now to apply after we add our sub-views
            var newConstraints: [NSLayoutConstraint] = []
            for oldConstraint in view.constraints {
                let firstItem = oldConstraint.firstItem === view ? self : oldConstraint.firstItem!
                let secondItem = oldConstraint.secondItem === view ? self : oldConstraint.secondItem
                newConstraints.append(NSLayoutConstraint(item: firstItem, attribute: oldConstraint.firstAttribute, relatedBy: oldConstraint.relation, toItem: secondItem, attribute: oldConstraint.secondAttribute, multiplier: oldConstraint.multiplier, constant: oldConstraint.constant))
            }
            
            /// Steal subviews from the original NSView which will not be used.
            /// Adding it to the new view removes it from the older one
            for newView in view.subviews {
                self.addSubview(newView)
            }
            
            /// Add the constraints
            /// Note that we add them to ourself. They must be added at or above the views mentioned in the constraints
            self.addConstraints(newConstraints)
        }
    }
}
