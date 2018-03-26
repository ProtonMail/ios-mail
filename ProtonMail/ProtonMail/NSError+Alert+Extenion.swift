//
//  NSError+Alert+Extenion.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/13/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation
import MBProgressHUD


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
        let window : UIWindow = UIApplication.shared.keyWindow as UIWindow!
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.labelText = NSLocalizedString("Alert", comment: "Title");
        hud.detailsLabelText = localizedDescription
        hud.removeFromSuperViewOnHide = true
        hud.hide(true, afterDelay: 3)
    }
    
    public func alert(at view: UIView) ->Void {
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: view, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.labelText = NSLocalizedString("Alert", comment: "Title");
        hud.detailsLabelText = localizedDescription
        hud.removeFromSuperViewOnHide = true
        hud.hide(true, afterDelay: 3)
    }
    
    public func alertErrorToast() ->Void {
        let window : UIWindow = UIApplication.shared.keyWindow as UIWindow!
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.labelText = NSLocalizedString(localizedDescription, comment: "Title");
        hud.detailsLabelText = description
        hud.removeFromSuperViewOnHide = true
        hud.hide(true, afterDelay: 3)
    }
    
    
    public func alertHumanCheckErrorToast() ->Void {
        let window : UIWindow = UIApplication.shared.keyWindow as UIWindow!
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.detailsLabelText = "\(NSLocalizedString("Human Check Failed", comment: "Description")): \(self.localizedDescription)"
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.yOffset = 250.0
        hud.hide(true, afterDelay: 3)
    }
    
    
    public class func alertOfflineToast() ->Void {
        let window : UIWindow = UIApplication.shared.keyWindow as UIWindow!
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.labelText = NSLocalizedString("Alert", comment: "Title");
        hud.detailsLabelText = NSLocalizedString("ProtonMail is currently offline, check our twitter for the current status: https://twitter.com/protonmail", comment: "Description");
        hud.removeFromSuperViewOnHide = true
        hud.hide(true, afterDelay: 3)
    }
    
    public class func alertMessageSendingToast() ->Void {
        let window : UIWindow = UIApplication.shared.keyWindow as UIWindow!
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.detailsLabelText = NSLocalizedString("Sending Message", comment: "Description");
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.yOffset = 250.0
        hud.hide(true, afterDelay: 1)
    }
    
    public class func sendingToast(at view: UIView) ->Void {
        let window : UIWindow = UIApplication.shared.keyWindow as UIWindow!
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.detailsLabelText = NSLocalizedString("Sending Message", comment: "Description");
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.yOffset = 250.0
        hud.hide(true, afterDelay: 1)
    }
    
    public class func alertMessageSentErrorToast() ->Void {
        let window : UIWindow = UIApplication.shared.keyWindow as UIWindow!
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.detailsLabelText = NSLocalizedString("Message sending failed please try again", comment: "Description");
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.yOffset = 250.0
        hud.hide(true, afterDelay: 2)
    }
    
}
