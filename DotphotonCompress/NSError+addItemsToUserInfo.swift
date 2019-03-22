//
//  NSError+addItemsToUserInfo.swift
//  DotphotonCompress
//
//  Created by Christoph Clausen on 25.07.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Foundation

extension NSError {
    
    func addItemsToUserInfo(newUserInfo: Dictionary<String, String>) -> NSError {
        
        var currentUserInfo = userInfo
        newUserInfo.forEach { (key, value) in
            currentUserInfo[key] = value
        }
        return NSError(domain: domain, code: code, userInfo: currentUserInfo)
    }
}
