//
//  NSError+Alert+Extenion.swift
//  ProtonMail - Created on 7/13/17.
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
        let message = localizedFailureReason ?? localizedDescription
        MBProgressHUD.alertToast(errorString: message)
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
        LocalString._messages_sending_message.alertToastBottom()
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
        details.alertToast()
    }

}
