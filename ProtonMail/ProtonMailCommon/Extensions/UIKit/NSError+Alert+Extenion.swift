//
//  NSError+Alert+Extenion.swift
//  ProtonMail - Created on 7/13/17.
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

    func alertController(title: String? = nil) -> UIAlertController {
        var message = localizedFailureReason

        if localizedRecoverySuggestion != nil {
            if message != nil {
                message = message! + "\n\n"
            } else {
                message = ""
            }

            message = message! + localizedRecoverySuggestion!
        }
        let _title = title ?? localizedDescription
        return UIAlertController(title: _title, message: localizedDescription, preferredStyle: .alert)

    }

    func alertToast() {
        let message = localizedFailureReason ?? localizedDescription
        MBProgressHUD.alert(errorString: message)
    }

    func alert(at view: UIView) {
        MBProgressHUD.alert(errorString: localizedDescription, at: view)
    }

    func alertErrorToast() {
        guard let window: UIWindow = UIApplication.shared.keyWindow else {
            return
        }
        let hud: MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.label.text = NSLocalizedString(localizedDescription, comment: "Title")
        hud.detailsLabel.text = description
        hud.removeFromSuperViewOnHide = true
        hud.hide(animated: true, afterDelay: 3)
    }

    func alertHumanCheckErrorToast() {
        guard let window: UIWindow = UIApplication.shared.keyWindow else {
            return
        }
        let hud: MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.detailsLabel.text = "\(LocalString._error_human_check_failed): \(self.localizedDescription)"
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.offset.y = 250.0
        hud.hide(animated: true, afterDelay: 3)
    }

    class func alertMessageSentErrorToast() {
        guard let window: UIWindow = UIApplication.shared.keyWindow else {
            return
        }
        let hud: MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.detailsLabel.text = LocalString._messages_sending_failed_try_again
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.offset.y = 250.0
        hud.hide(animated: true, afterDelay: 2)
    }

    class func alertMessageSentError(details: String) {
        guard let window: UIWindow = UIApplication.shared.keyWindow else {
            return
        }
        let hud: MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.detailsLabel.text = LocalString._messages_sending_failed_try_again + " " + details
        hud.removeFromSuperViewOnHide = true
        hud.margin = 10
        hud.offset.y = 250.0
        hud.hide(animated: true, afterDelay: 2)
    }

    class func alertSavingDraftError(details: String) {
        details.alertToast()
    }

}
