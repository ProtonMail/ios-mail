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
    
    func checkSpace(_ usedSpace: Int64, maxSpace: Int64) {
        
        if userCachedStatus.isCheckSpaceDisabled {
            return
        }
        
        let maxSpace : Double = Double(maxSpace)
        let usedSpace : Double = Double(usedSpace) // * 160)
        let percentage : Double = Double(Constants.App.SpaceWarningThresholdDouble / 100)
        let threshold : Double = percentage * maxSpace
        
        if maxSpace == 0 || usedSpace < threshold {
            return
        }
        
        let formattedMaxSpace : String = ByteCountFormatter.string(fromByteCount: Int64(maxSpace), countStyle: ByteCountFormatter.CountStyle.file)
        var message = ""
        
        if usedSpace >= maxSpace {
            let localized = NSLocalizedString("You have used up all of your storage space (%@).", comment: "Description")
            if localized.count <= 0 || !localized.contains(check: "%@") {
                message = String(format: "You have used up all of your storage space (%@).", formattedMaxSpace);
            } else {
                message = String(format: localized, formattedMaxSpace);
            }
        } else {
            message = String(format: NSLocalizedString("You have used %d%% of your storage space (%@).", comment: "Description"), Constants.App.SpaceWarningThreshold, formattedMaxSpace);
        }
        
        let alertController = UIAlertController(title: LocalString._space_warning,
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addOKAction()
        alertController.addAction(UIAlertAction(title: LocalString._hide, style: .destructive, handler: { action in
            userCachedStatus.isCheckSpaceDisabled = true
        }))

        UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
    }
}
