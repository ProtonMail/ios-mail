//
//  MBProgressHUD+Helper.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/10/23.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import MBProgressHUD

extension MBProgressHUD
{
    class func alertToast(errorString: String) -> Void {
        guard let window = UIApplication.shared.keyWindow else {
            return
        }
        let hud: MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.labelText = LocalString._general_alert_title
        hud.detailsLabelText = errorString
        hud.removeFromSuperViewOnHide = true
        hud.hide(true, afterDelay: 3)
    }
    
    class func alert(at view: UIView, errorString: String) ->Void {
        let hud: MBProgressHUD = MBProgressHUD.showAdded(to: view, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.labelText = LocalString._general_alert_title
        hud.detailsLabelText = errorString
        hud.removeFromSuperViewOnHide = true
        hud.hide(true, afterDelay: 3)
    }
}
