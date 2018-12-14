//
//  StorageLimit.swift
//  ProtonMail
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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
