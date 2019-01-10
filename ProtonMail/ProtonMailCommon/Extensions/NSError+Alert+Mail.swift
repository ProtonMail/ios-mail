//
//  NSError+Alert+Mail.swift
//  ProtonMail - Created on 9/26/17.
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
