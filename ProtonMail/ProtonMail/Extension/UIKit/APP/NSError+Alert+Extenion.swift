//
//  NSError+Alert+Extenion.swift
//  Proton Mail - Created on 7/13/17.
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
        var message = localizedFailureReason ?? .empty

        if let recoverySuggestion = localizedRecoverySuggestion {
            if !message.isEmpty {
                message += "\n\n"
            }
            message += recoverySuggestion
        }
        if message.isEmpty {
            message = localizedDescription
        }
        let alertTitle = title ?? localizedDescription
        let alertMessage = alertTitle == message ? nil : message
        return UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
    }

    func alertToast() {
        let message = localizedFailureReason ?? localizedDescription
        MBProgressHUD.alert(errorString: message)
    }

    func alertErrorToast() {
        guard let window = UIApplication.shared.topMostWindow else {
            return
        }
        let hud: MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.label.text = NSLocalizedString(localizedDescription, comment: "Title")
        hud.detailsLabel.text = description
        hud.removeFromSuperViewOnHide = true
        hud.hide(animated: true, afterDelay: 3)
    }

    @MainActor
    class func alertSavingDraftError(details: String) {
        details.alertToast()
    }

}
