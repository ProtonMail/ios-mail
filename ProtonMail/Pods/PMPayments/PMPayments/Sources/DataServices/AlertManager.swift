//
//  AlertManager.swift
//  PMPayments - Created on 2/12/2020.
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

#if os(iOS)
import UIKit
import PMCoreTranslation

typealias ActionCallback = ((UIAlertAction) -> Void)?

class PaymentsAlertManager {
    let alertManager: AlertManagerProtocol

    init (alertManager: AlertManagerProtocol = AlertManager()) {
        self.alertManager = alertManager
    }

    func retryAlert(confirmAction: ActionCallback = nil, cancelAction: ActionCallback = nil) {
        alertManager.title = CoreString._error_apply_payment_on_registration_title
        alertManager.message = CoreString._error_apply_payment_on_registration_message
        alertManager.confirmButtonTitle = CoreString._retry
        alertManager.cancelButtonTitle = CoreString._error_apply_payment_on_registration_support
        alertManager.confirmButtonStyle = .destructive
        alertManager.cancelButtonStyle = .cancel
        alertManager.showAlert(confirmAction: confirmAction, cancelAction: cancelAction)
    }

    func retryCancelAlert(confirmAction: ActionCallback = nil) {
        alertManager.title = CoreString._error_unknown_title
        alertManager.message = ""
        alertManager.confirmButtonTitle = CoreString._general_ok_action
        alertManager.cancelButtonTitle = nil
        alertManager.confirmButtonStyle = .default
        alertManager.cancelButtonStyle = .default
        alertManager.showAlert(confirmAction: confirmAction, cancelAction: nil)
    }

    func userValidationAlert(message: String, confirmButtonTitle: String, confirmAction: ActionCallback = nil) {
        alertManager.title = CoreString._warning
        alertManager.message = message
        alertManager.confirmButtonTitle = confirmButtonTitle
        alertManager.cancelButtonTitle = CoreString._no_dont_bypass_validation
        alertManager.confirmButtonStyle = .destructive
        alertManager.cancelButtonStyle = .cancel
        alertManager.showAlert(confirmAction: confirmAction, cancelAction: nil)
    }

    func errorAlert(message: String) {
        alertManager.title = CoreString._error_occured
        alertManager.message = message
        alertManager.confirmButtonTitle = CoreString._general_ok_action
        alertManager.cancelButtonTitle = nil
        alertManager.confirmButtonStyle = .cancel
        alertManager.cancelButtonStyle = .default
        alertManager.showAlert(confirmAction: nil, cancelAction: nil)
    }
}

protocol AlertManagerProtocol: class {
    var title: String? { get set }
    var message: String? { get set }
    var confirmButtonTitle: String? { get set }
    var cancelButtonTitle: String? { get set }
    var confirmButtonStyle: UIAlertAction.Style { get set }
    var cancelButtonStyle: UIAlertAction.Style { get set }
    func showAlert(confirmAction: ActionCallback, cancelAction: ActionCallback)
}

private class AlertManager: AlertManagerProtocol {
    var title: String?
    var message: String?
    var confirmButtonTitle: String?
    var cancelButtonTitle: String?
    var confirmButtonStyle: UIAlertAction.Style = .default
    var cancelButtonStyle: UIAlertAction.Style = .default

    func showAlert(confirmAction: ActionCallback = nil, cancelAction: ActionCallback = nil) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: self.title, message: self.message, preferredStyle: .alert)
            if let cancelButtonTitle = self.cancelButtonTitle {
                alert.addAction(UIAlertAction(title: cancelButtonTitle, style: self.cancelButtonStyle, handler: cancelAction))
            }
            if let confirmButtonTitle = self.confirmButtonTitle {
                alert.addAction(UIAlertAction(title: confirmButtonTitle, style: self.confirmButtonStyle, handler: confirmAction))
            }
            guard let window = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first else { return }
            window.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
}

#endif
