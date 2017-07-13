//
//  NSError+Alert+Extenion.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/13/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation


extension NSError {

    public func alertController() -> UIAlertController {
        var message = localizedFailureReason
        
        if localizedRecoverySuggestion != nil {
            if message != nil {
                message = message! + "\n\n"
            } else {
                message = ""
            }
            
            message = message! + localizedRecoverySuggestion!
        }
        return UIAlertController(title: localizedDescription, message: message, preferredStyle: .alert)
    }
    
    public func alertController(_ title : String) -> UIAlertController {
        var message = localizedFailureReason
        
        if localizedRecoverySuggestion != nil {
            if message != nil {
                message = message! + "\n\n"
            } else {
                message = ""
            }
            
            message = message! + localizedRecoverySuggestion!
        }
        return UIAlertController(title: title, message: localizedDescription, preferredStyle: .alert)
    }
    
    
    public func alertToast() ->Void {
        let window : UIWindow = UIApplication.shared.windows.last as UIWindow!
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.labelText = NSLocalizedString("Alert", comment: "Title");
        hud.detailsLabelText = localizedDescription
        hud.removeFromSuperViewOnHide = true
        hud.hide(true, afterDelay: 3)
    }
    
    public func alertErrorToast() ->Void {
        let window : UIWindow = UIApplication.shared.windows.last as UIWindow!
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.labelText = NSLocalizedString(localizedDescription, comment: "Title");
        hud.detailsLabelText = description
        hud.removeFromSuperViewOnHide = true
        hud.hide(true, afterDelay: 3)
    }
    
    public func alertSentErrorToast() ->Void {
        let window : UIWindow = UIApplication.shared.windows.last as UIWindow!
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        let _ = NSLocalizedString("Sending Failed", comment: "Description")
        hud.detailsLabelText = "\(NSLocalizedString("Sent Failed", comment: "Description")): \(self.localizedDescription)"
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.yOffset = 250.0
        hud.hide(true, afterDelay: 3)
    }
    
    public func alertHumanCheckErrorToast() ->Void {
        let window : UIWindow = UIApplication.shared.windows.last as UIWindow!
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.detailsLabelText = "\(NSLocalizedString("Human Check Failed", comment: "Description")): \(self.localizedDescription)"
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.yOffset = 250.0
        hud.hide(true, afterDelay: 3)
    }
    
    
    public class func alertUpdatedToast() ->Void {
        let window : UIWindow = UIApplication.shared.windows.last as UIWindow!
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.labelText = NSLocalizedString("Alert", comment: "Title");
        hud.detailsLabelText = NSLocalizedString("A new version of ProtonMail app is available, please update to latest version.", comment: "Description");
        hud.removeFromSuperViewOnHide = true
        hud.hide(true, afterDelay: 3)
    }
    
    public class func alertBadTokenToast() ->Void {
        let window : UIWindow = UIApplication.shared.windows.last as UIWindow!
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.labelText = NSLocalizedString("Alert", comment: "Title");
        hud.detailsLabelText = NSLocalizedString("Invalid access token please relogin", comment: "Description");
        hud.removeFromSuperViewOnHide = true
        hud.hide(true, afterDelay: 3)
    }
    
    public class func alertOfflineToast() ->Void {
        let window : UIWindow = UIApplication.shared.windows.last as UIWindow!
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.labelText = NSLocalizedString("Alert", comment: "Title");
        hud.detailsLabelText = NSLocalizedString("ProtonMail is currently offline, check our twitter for the current status: https://twitter.com/protonmail", comment: "Description");
        hud.removeFromSuperViewOnHide = true
        hud.hide(true, afterDelay: 3)
    }
    
    public class func alertMessageSendingToast() ->Void {
        let window : UIWindow = UIApplication.shared.windows.last as UIWindow!
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.detailsLabelText = NSLocalizedString("Sending Message", comment: "Description");
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.yOffset = 250.0
        hud.hide(true, afterDelay: 1)
    }
    
    public class func alertMessageSentToast() ->Void {
        let window : UIWindow = UIApplication.shared.windows.last as UIWindow!
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.detailsLabelText = NSLocalizedString("Message sent", comment: "Description");
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.yOffset = 250.0
        hud.hide(true, afterDelay: 1)
    }
    
    public class func alertMessageSentErrorToast() ->Void {
        let window : UIWindow = UIApplication.shared.windows.last as UIWindow!
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.detailsLabelText = NSLocalizedString("Message sending failed please try again", comment: "Description");
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.yOffset = 250.0
        hud.hide(true, afterDelay: 2)
    }
    
    public class func alertLocalCacheErrorToast() ->Void {
        let window : UIWindow = UIApplication.shared.windows.last as UIWindow!
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.detailsLabelText = NSLocalizedString("The draft cache is broken please try again", comment: "Description");
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.yOffset = 250.0
        hud.hide(true, afterDelay: 2)
    }
}
