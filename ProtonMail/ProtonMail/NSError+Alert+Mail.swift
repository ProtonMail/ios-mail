//
//  NSError+Alert+Mail.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 9/26/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation



extension NSError {
    
    
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
    
    
    public class func alertBadTokenToast() ->Void {
        let window : UIWindow = UIApplication.shared.windows.last as UIWindow!
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.labelText = NSLocalizedString("Alert", comment: "Title");
        hud.detailsLabelText = NSLocalizedString("Invalid access token please relogin", comment: "Description");
        hud.removeFromSuperViewOnHide = true
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
}
