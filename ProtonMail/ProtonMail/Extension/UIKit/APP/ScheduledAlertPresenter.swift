// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import UIKit

protocol ScheduledAlertPresenter: AnyObject {
    func displayScheduledAlert(scheduledNum: Int, continueAction: @escaping () -> Void)
    func displayScheduledAlert(scheduledNum: Int, continueAction: @escaping () -> Void, cancelAction: (() -> Void)?)
}

extension ScheduledAlertPresenter where Self: UIViewController {
    func displayScheduledAlert(scheduledNum: Int, continueAction: @escaping () -> Void, cancelAction: (() -> Void)?) {
        let title = LocalString._delete_scheduled_alert_title
        let message = String(format: LocalString._delete_scheduled_alert_message, scheduledNum)
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addCancelAction { _ in
            cancelAction?()
        }
        alert.addOKAction { _ in
            continueAction()
        }
        self.present(alert, animated: true, completion: nil)
    }

    func displayScheduledAlert(scheduledNum: Int, continueAction: @escaping () -> Void) {
        displayScheduledAlert(scheduledNum: scheduledNum, continueAction: continueAction, cancelAction: nil)
    }
}
