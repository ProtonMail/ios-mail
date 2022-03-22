//
//  NSError+Alert+Mail.swift
//  ProtonMail - Created on 9/26/17.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import MBProgressHUD

extension NSError {

    static var isAlertShown = false

    class func alertMessageSentToast() {
        guard let window: UIWindow = UIApplication.shared.keyWindow else {
            return
        }
        let hud: MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.detailsLabel.text = LocalString._message_sent_ok_desc
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.offset.y = 250.0
        hud.hide(animated: true, afterDelay: 1)
    }

    func alertSentErrorToast() {
        guard let window: UIWindow = UIApplication.shared.keyWindow else {
            return
        }
        let hud: MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.detailsLabel.text = "\(LocalString._message_sent_failed_desc): \(self.localizedDescription)"
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.offset.y = 250.0
        hud.hide(animated: true, afterDelay: 3)
    }

    class func alertLocalCacheErrorToast() {
        guard let window: UIWindow = UIApplication.shared.keyWindow else {
            return
        }
        let hud: MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.detailsLabel.text = LocalString._message_draft_cache_is_broken
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.offset.y = 250.0
        hud.hide(animated: true, afterDelay: 2)
    }

    class func alertBadToken() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) {
            guard let window = UIApplication.shared.keyWindow, !NSError.isAlertShown else {
                return
            }
            NSError.isAlertShown = true

            let message = LocalString._general_invalid_access_token
            let title = LocalString._general_alert_title
            let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertVC.addOKAction { (_) in
                NSError.isAlertShown = false
            }
            window.topmostViewController()?.present(alertVC, animated: true, completion: nil)
        }
    }
}
