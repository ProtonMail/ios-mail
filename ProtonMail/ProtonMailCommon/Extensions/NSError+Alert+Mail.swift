//
//  NSError+Alert+Mail.swift
//  ProtonMail - Created on 9/26/17.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation
import MBProgressHUD

extension NSError {
    
    public class func alertMessageSentToast() ->Void {
        guard let window : UIWindow = UIApplication.shared.keyWindow else {
            return
        }
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.detailsLabel.text = LocalString._message_sent_ok_desc
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.offset.y = 250.0
        hud.hide(animated: true, afterDelay: 1)
    }
    
    
    public func alertSentErrorToast() ->Void {
        guard let window : UIWindow = UIApplication.shared.keyWindow else {
            return
        }
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.detailsLabel.text = "\(LocalString._message_sent_failed_desc): \(self.localizedDescription)"
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.offset.y = 250.0
        hud.hide(animated: true, afterDelay: 3)
    }
    
    
    public class func alertLocalCacheErrorToast() ->Void {
        guard let window : UIWindow = UIApplication.shared.keyWindow else {
            return
        }
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.detailsLabel.text = LocalString._message_draft_cache_is_broken
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.offset.y = 250.0
        hud.hide(animated: true, afterDelay: 2)
    }
    
    
    public class func alertBadTokenToast() ->Void {
        guard let window : UIWindow = UIApplication.shared.keyWindow else {
            return
        }
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.label.text = LocalString._general_alert_title
        hud.detailsLabel.text = LocalString._general_invalid_access_token
        hud.removeFromSuperViewOnHide = true
        hud.offset.y = 250.0
        hud.hide(animated: true, afterDelay: 3)
    }
    
    
    
    public class func alertUpdatedToast() ->Void {
        guard let window : UIWindow = UIApplication.shared.keyWindow else {
            return
        }
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.label.text = LocalString._general_alert_title
        hud.detailsLabel.text = LocalString._general_force_upgrade_desc
        hud.removeFromSuperViewOnHide = true
        hud.hide(animated: true, afterDelay: 3)
    }
}
