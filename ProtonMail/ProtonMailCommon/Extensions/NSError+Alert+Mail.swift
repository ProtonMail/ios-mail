//
//  NSError+Alert+Mail.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 9/26/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation
import MBProgressHUD

extension NSError {
    
    public class func alertMessageSentToast() ->Void {
        guard let window : UIWindow = UIApplication.shared.keyWindow else {
            return
        }
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.detailsLabelText = LocalString._message_sent_ok_desc
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.yOffset = 250.0
        hud.hide(true, afterDelay: 1)
    }
    
    
    public func alertSentErrorToast() ->Void {
        guard let window : UIWindow = UIApplication.shared.keyWindow else {
            return
        }
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.detailsLabelText = "\(LocalString._message_sent_failed_desc): \(self.localizedDescription)"
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.yOffset = 250.0
        hud.hide(true, afterDelay: 3)
    }
    
    
    public class func alertLocalCacheErrorToast() ->Void {
        guard let window : UIWindow = UIApplication.shared.keyWindow else {
            return
        }
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.detailsLabelText = LocalString._message_draft_cache_is_broken
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.yOffset = 250.0
        hud.hide(true, afterDelay: 2)
    }
    
    
    public class func alertBadTokenToast() ->Void {
        guard let window : UIWindow = UIApplication.shared.keyWindow else {
            return
        }
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.labelText = LocalString._general_alert_title
        hud.detailsLabelText = LocalString._general_invalid_access_token
        hud.removeFromSuperViewOnHide = true
        hud.hide(true, afterDelay: 3)
    }
    
    
    
    public class func alertUpdatedToast() ->Void {
        guard let window : UIWindow = UIApplication.shared.keyWindow else {
            return
        }
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.labelText = LocalString._general_alert_title
        hud.detailsLabelText = LocalString._general_force_upgrade_desc
        hud.removeFromSuperViewOnHide = true
        hud.hide(true, afterDelay: 3)
    }
}
