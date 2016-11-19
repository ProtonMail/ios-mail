//
//  StorageLimit.swift
//  ProtonMail
//
//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation

let storageLimit = StorageLimit()

class StorageLimit {
    
    // MARK: - Public methods
    
    func checkSpace(usedSpace: Int64, maxSpace: Int64) {
        
        if userCachedStatus.isCheckSpaceDisabled {
            return
        }
        
        let maxSpace = Double(maxSpace)
        let usedSpace = Double(usedSpace)
        let threshold = AppConstants.SpaceWarningThreshold/100.0 * maxSpace
        
        if maxSpace == 0 || usedSpace < threshold {
            return
        }
        
        let formattedMaxSpace = NSByteCountFormatter.stringFromByteCount(Int64(maxSpace), countStyle: NSByteCountFormatterCountStyle.File)
        var message = ""
        
        if usedSpace >= maxSpace {
            message = NSLocalizedString("You have used up all of your storage space (\(formattedMaxSpace)).")
        } else {
            message = NSLocalizedString("You have used \(AppConstants.SpaceWarningThreshold)% of your storage space (\(formattedMaxSpace)).")
        }
        
        let alertController = UIAlertController(
            title: NSLocalizedString("Space Warning"),
            message: message,
            preferredStyle: .Alert)
        alertController.addOKAction()
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Hide"), style: .Destructive, handler: { action in
            userCachedStatus.isCheckSpaceDisabled = true
        }))
        
        UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
    }
}
