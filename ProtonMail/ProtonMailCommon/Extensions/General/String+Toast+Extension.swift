//
//  String+Toast+Extension.swift
//  ProtonMail - Created on 7/31/17.
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

extension String {
    
    public func alertToast(withTitle: Bool=true) -> Void {
        var application: UIApplication?

        #if APP_EXTENSION
        let obj = UIApplication.perform(Selector("sharedApplication"))
        application = obj?.takeRetainedValue() as? UIApplication
        #else
        application = UIApplication.shared
        #endif
        
        guard let window : UIWindow = application?.keyWindow else {
            return
        }
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        if withTitle {
            hud.label.text = LocalString._general_alert_title
        }
        hud.detailsLabel.text = self
        hud.removeFromSuperViewOnHide = true
        hud.hide(animated: true, afterDelay: 3)
    }
    
    public func alertToastBottom() ->Void {
        var application: UIApplication?

        #if APP_EXTENSION
        let obj = UIApplication.perform(Selector("sharedApplication"))
        application = obj?.takeRetainedValue() as? UIApplication
        #else
        application = UIApplication.shared
        #endif
        
        guard let window : UIWindow = application?.keyWindow else {
            return
        }
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.detailsLabel.text = self
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.offset.y = 250.0
        hud.hide(animated: true, afterDelay: 1)
    }
    
    /**
     show toast message at top of the view
     
     - Parameter view: will show the toast message on top of this view
     
     - Returns: void
     **/
    func toast(at view: UIView) -> Void {
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: view, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.label.text = LocalString._general_alert_title
        hud.detailsLabel.text = self
        hud.removeFromSuperViewOnHide = true
        hud.hide(animated: true, afterDelay: 3)
    }
    
}
