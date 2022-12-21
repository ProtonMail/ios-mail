// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation
import MBProgressHUD
import UIKit

final class SendMessageResultNotificationHandler {

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sendMessageTaskNotification),
            name: .sendMessageTaskSuccess,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sendMessageTaskNotification),
            name: .sendMessageTaskFail,
            object: nil
        )
    }

    @objc
    private func sendMessageTaskNotification(notification: Notification) {
        switch notification.name {
        case .sendMessageTaskSuccess:
            handleSendMessageTaskSuccess()
        case .sendMessageTaskFail:
            handleSendMessageTaskFail(userInfo: notification.userInfo)
        default:
            break
        }
    }

    private func handleSendMessageTaskSuccess() {
        #if APP_EXTENSION
        DispatchQueue.main.async {
            NSError.alertMessageSentToast()
        }
        #endif
    }

    private func handleSendMessageTaskFail(userInfo: [AnyHashable: Any]?) {
        let errorMessage: String
        if let userInfo = userInfo, let message = userInfo[Notification.UserInfoKey.errorMessage] as? String {
            errorMessage = message
        } else {
            errorMessage = LocalString._messages_sending_failed_try_again
        }
        DispatchQueue.main.async {
            #if APP_EXTENSION
            NotificationCenter.default.post(
                name: NSError.errorOccuredNotification,
                object: nil,
                userInfo: ["text": errorMessage]
            )
            #else
            guard let window: UIWindow = UIApplication.shared.keyWindow else {
                return
            }
            let hud: MBProgressHUD = MBProgressHUD.showAdded(to: window, animated: true)
            hud.mode = MBProgressHUDMode.text
            hud.detailsLabel.text = errorMessage
            hud.removeFromSuperViewOnHide = true
            hud.margin = 10
            hud.offset.y = 250.0
            hud.hide(animated: true, afterDelay: 3)
            #endif
        }
    }
}
