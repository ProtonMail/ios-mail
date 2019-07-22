//
//  NSError+Alert+Extenion.swift
//  ProtonMail - Created on 7/13/17.
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
        MBProgressHUD.alertToast(errorString: localizedDescription)
    }
    
    public func alert(at view: UIView) ->Void {
        MBProgressHUD.alert(at: view, errorString: localizedDescription)
    }
    
    public func alertErrorToast() ->Void {
        guard let window : UIWindow = UIApplication.shared.keyWindow else {
            return
        }
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.label.text = NSLocalizedString(localizedDescription, comment: "Title");
        hud.detailsLabel.text = description
        hud.removeFromSuperViewOnHide = true
        hud.hide(animated: true, afterDelay: 3)
    }
    
    
    public func alertHumanCheckErrorToast() ->Void {
        guard let window : UIWindow = UIApplication.shared.keyWindow else {
            return
        }
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.detailsLabel.text = "\(LocalString._error_human_check_failed): \(self.localizedDescription)"
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.offset.y = 250.0
        hud.hide(animated: true, afterDelay: 3)
    }
    
    public class func alertMessageSendingToast() ->Void {
        guard let window : UIWindow = UIApplication.shared.keyWindow else {
            return
        }
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.detailsLabel.text = LocalString._messages_sending_message
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.offset.y = 250.0
        hud.hide(animated: true, afterDelay: 1)
    }
    
    public class func sendingToast(at view: UIView) ->Void {
        guard let window : UIWindow = UIApplication.shared.keyWindow else {
            return
        }
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.detailsLabel.text = LocalString._messages_sending_message
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.offset.y = 250.0
        hud.hide(animated: true, afterDelay: 1)
    }
    
    public class func alertMessageSentErrorToast() ->Void {
        guard let window : UIWindow = UIApplication.shared.keyWindow else {
            return
        }
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.detailsLabel.text = LocalString._messages_sending_failed_try_again
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.offset.y = 250.0
        hud.hide(animated: true, afterDelay: 2)
    }
    
    public class func alertMessageSentError(details : String) -> Void {
        guard let window : UIWindow = UIApplication.shared.keyWindow else {
            return
        }
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.detailsLabel.text = LocalString._messages_sending_failed_try_again + " " + details
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.offset.y = 250.0
        hud.hide(animated: true, afterDelay: 2)
    }
    
    
    public class func alertSavingDraftError(details : String) -> Void {
        guard let window : UIWindow = UIApplication.shared.keyWindow else {
            return
        }
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.detailsLabel.text = details
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.offset.y = 250.0
        hud.hide(animated: true, afterDelay: 4)
    }

}
