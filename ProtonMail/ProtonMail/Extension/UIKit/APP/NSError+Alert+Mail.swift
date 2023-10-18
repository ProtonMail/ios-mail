//
//  NSError+Alert+Mail.swift
//  Proton Mail - Created on 9/26/17.
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

    class func alertBadToken(in window: UIWindow) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) {
            guard !NSError.isAlertShown else {
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
