//
//  NSColor+Theme.swift
//  DotphotonConvert
//
//  Created by Christoph Clausen on 13.04.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Cocoa

extension NSColor {
    struct Theme {
        static let border = NSColor(white: 0.847, alpha: 1)
        static let buttonBlue = NSColor(red: 0.092, green: 0, blue: 1, alpha: 1)
        static let buttonHover = NSColor(white: 0.788, alpha: 1)
        static let buttonWhite = NSColor.white
        static let itemSelected = NSColor(red: 0, green: 0.478, blue: 1, alpha: 1)
        static let pauseCircle = NSColor(red: 0.624, green: 0.902, blue: 0.984, alpha: 1)
        static let startButtonText = NSColor(white: 0.949, alpha: 1)
        static let textDark = NSColor(white: 0.243, alpha: 1)
        static let textLight = NSColor(white: 0.620, alpha: 1)
        static let windowBackground = NSColor(white: 0.969, alpha: 1)
    }
}
