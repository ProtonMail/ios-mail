//
//  NSErrorExtension.swift
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

extension NSError {
    
    convenience init(domain: String, code: Int, localizedDescription: String, localizedFailureReason: String? = nil, localizedRecoverySuggestion: String? = nil) {
        var userInfo = [NSLocalizedDescriptionKey : localizedDescription]
        
        if let localizedFailureReason = localizedFailureReason {
            userInfo[NSLocalizedFailureReasonErrorKey] = localizedFailureReason
        }
        
        if let localizedRecoverySuggestion = localizedRecoverySuggestion {
            userInfo[NSLocalizedRecoverySuggestionErrorKey] = localizedRecoverySuggestion
        }
        
        self.init(domain: domain, code: code, userInfo: userInfo)
    }
    
    class func protonMailError(#code: Int, localizedDescription: String, localizedFailureReason: String? = nil, localizedRecoverySuggestion: String? = nil) -> NSError {
        return NSError(domain: protonMailErrorDomain(), code: code, localizedDescription: localizedDescription, localizedFailureReason: localizedFailureReason, localizedRecoverySuggestion: localizedRecoverySuggestion)
    }
    
    class func protonMailErrorDomain(subdomain: String? = nil) -> String {
        var domain = NSBundle.mainBundle().bundleIdentifier ?? "ch.protonmail"
        
        if let subdomain = subdomain {
            domain += ".\(subdomain)"
        }
        
        return domain
    }
    
    func alertController() -> UIAlertController {
        var message = localizedFailureReason
        
        if localizedRecoverySuggestion != nil {
            if message != nil {
                message = message! + "\n\n"
            } else {
                message = ""
            }
            
            message = message! + localizedRecoverySuggestion!
        }
        return UIAlertController(title: localizedDescription, message: message, preferredStyle: .Alert)
    }
    
    class func alertUpdatedToast() ->Void {
        let window : UIWindow = UIApplication.sharedApplication().windows.last as! UIWindow
        var hud : MBProgressHUD = MBProgressHUD.showHUDAddedTo(window, animated: true)
        hud.mode = MBProgressHUDMode.Text
        hud.labelText = "Alert";
        hud.detailsLabelText = "ProtonMail is currently offline, please check our twitter for the current status @ProtonMail.";
        hud.removeFromSuperViewOnHide = true
        hud.hide(true, afterDelay: 3)
        //                    hud.mode = MBProgressHUDMode.Text
        //                    hud.labelText = "Sending message ..."
        //                    hud.removeFromSuperViewOnHide = true
        //                    hud.margin = 10
        //                    hud.yOffset = 150
    }
    
    class func alertBadTokenToast() ->Void {
        let window : UIWindow = UIApplication.sharedApplication().windows.last as! UIWindow
        var hud : MBProgressHUD = MBProgressHUD.showHUDAddedTo(window, animated: true)
        hud.mode = MBProgressHUDMode.Text
        hud.labelText = "Alert";
        hud.detailsLabelText = "Invalid access token please relogin";
        hud.removeFromSuperViewOnHide = true
        hud.hide(true, afterDelay: 3)
        //                    hud.mode = MBProgressHUDMode.Text
        //                    hud.labelText = "Sending message ..."
        //                    hud.removeFromSuperViewOnHide = true
        //                    hud.margin = 10
        //                    hud.yOffset = 150
    }
    
    class func alertOfflineToast() ->Void {
        let window : UIWindow = UIApplication.sharedApplication().windows.last as! UIWindow
        var hud : MBProgressHUD = MBProgressHUD.showHUDAddedTo(window, animated: true)
        hud.mode = MBProgressHUDMode.Text
        hud.labelText = "Alert";
        hud.detailsLabelText = "ProtonMail is currently offline, check our twitter for the current status: https://twitter.com/protonmail";
        hud.removeFromSuperViewOnHide = true
        hud.hide(true, afterDelay: 3)

       // let alertController = UIAlertController(title: "Alert", message: "", preferredStyle: .Alert)
        
        
//        alertController.addAction(UIAlertAction(title: NSLocalizedString("Photo Library"), style: UIAlertActionStyle.Default, handler: { (action) -> Void in
//            let picker: UIImagePickerController = UIImagePickerController()
//            picker.delegate = self
//            picker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
//            self.presentViewController(picker, animated: true, completion: nil)
//        }))
//        
//        alertController.addAction(UIAlertAction(title: NSLocalizedString("Take a Photo"), style: UIAlertActionStyle.Default, handler: { (action) -> Void in
//            if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)) {
//                let picker: UIImagePickerController = UIImagePickerController()
//                picker.delegate = self
//                picker.sourceType = UIImagePickerControllerSourceType.Camera
//                self.presentViewController(picker, animated: true, completion: nil)
//            }
//        }))
//        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: UIAlertActionStyle.Cancel, handler: nil))
        
 //       window.addSubview(alertController.view);
        
        //window.perse
       //self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    class func alertMessageSendingToast() ->Void {
        let window : UIWindow = UIApplication.sharedApplication().windows.last as! UIWindow
        var hud : MBProgressHUD = MBProgressHUD.showHUDAddedTo(window, animated: true)
        hud.mode = MBProgressHUDMode.Text
        hud.detailsLabelText = "Sending Message";
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.yOffset = 250.0
        hud.hide(true, afterDelay: 0.5)
    }
    
    class func alertMessageSentToast() ->Void {
        let window : UIWindow = UIApplication.sharedApplication().windows.last as! UIWindow
        var hud : MBProgressHUD = MBProgressHUD.showHUDAddedTo(window, animated: true)
        hud.mode = MBProgressHUDMode.Text
        hud.detailsLabelText = "Message sent";
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.yOffset = 250.0
        hud.hide(true, afterDelay: 1)
    }

    class func alertMessageSentErrorToast() ->Void {
        let window : UIWindow = UIApplication.sharedApplication().windows.last as! UIWindow
        var hud : MBProgressHUD = MBProgressHUD.showHUDAddedTo(window, animated: true)
        hud.mode = MBProgressHUDMode.Text
        hud.detailsLabelText = "Message send error";
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.yOffset = 250.0
        hud.hide(true, afterDelay: 1)
    }
    
    class func unknowError() -> NSError {
        return apiServiceError(
            code: -1,
            localizedDescription: NSLocalizedString("Unknow Error"),
            localizedFailureReason: NSLocalizedString("Unknow Error!"))
    }
    
    
}