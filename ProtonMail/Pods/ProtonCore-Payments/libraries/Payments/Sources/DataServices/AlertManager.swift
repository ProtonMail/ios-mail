//
//  AlertManager.swift
//  ProtonCore-Payments - Created on 2/12/2020.
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_CoreTranslation
import ProtonCore_Foundations

public enum AlertActionStyle {
    case `default`
    case cancel
    case destructive
}

public protocol AlertManagerProtocol: AnyObject {
    var title: String? { get set }
    var message: String { get set }
    var confirmButtonTitle: String? { get set }
    var cancelButtonTitle: String? { get set }
    var confirmButtonStyle: AlertActionStyle { get set }
    var cancelButtonStyle: AlertActionStyle { get set }
    func showAlert(confirmAction: ActionCallback, cancelAction: ActionCallback)
}

public typealias ActionCallback = (() -> Void)?

struct PaymentsAlertManager {

    var alertManager: AlertManagerProtocol

    init (alertManager: AlertManagerProtocol) {
        self.alertManager = alertManager
    }

    func retryAlert(confirmAction: ActionCallback, cancelAction: ActionCallback) {
        alertManager.title = CoreString._error_apply_payment_on_registration_title
        alertManager.message = CoreString._error_apply_payment_on_registration_message
        alertManager.confirmButtonTitle = CoreString._retry
        alertManager.cancelButtonTitle = CoreString._error_apply_payment_on_registration_support
        alertManager.confirmButtonStyle = .destructive
        alertManager.cancelButtonStyle = .cancel
        alertManager.showAlert(confirmAction: confirmAction, cancelAction: cancelAction)
    }

    func userValidationAlert(message: String, confirmButtonTitle: String, confirmAction: ActionCallback) {
        alertManager.title = nil
        alertManager.message = message
        alertManager.confirmButtonTitle = confirmButtonTitle
        alertManager.cancelButtonTitle = CoreString._no_dont_bypass_validation
        alertManager.confirmButtonStyle = .destructive
        alertManager.cancelButtonStyle = .cancel
        alertManager.showAlert(confirmAction: confirmAction, cancelAction: nil)
    }

    func errorAlert(message: String) {
        alertManager.title = nil
        alertManager.message = message
        alertManager.confirmButtonTitle = CoreString._general_ok_action
        alertManager.cancelButtonTitle = nil
        alertManager.confirmButtonStyle = .cancel
        alertManager.cancelButtonStyle = .default
        alertManager.showAlert(confirmAction: nil, cancelAction: nil)
    }
}

#if canImport(UIKit)
import UIKit

extension AlertActionStyle {
    var toUIAlertActionStyle: UIAlertAction.Style {
        switch self {
        case .default: return .default
        case .cancel: return .cancel
        case .destructive: return .destructive
        }
    }
}

final class AlertManager: AlertManagerProtocol {
    var title: String?
    var message: String = ""
    var confirmButtonTitle: String?
    var cancelButtonTitle: String?
    var confirmButtonStyle: AlertActionStyle = .default
    var cancelButtonStyle: AlertActionStyle = .default

    init() {}

    func showAlert(confirmAction: ActionCallback = nil, cancelAction: ActionCallback = nil) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: self.title, message: self.message, preferredStyle: .alert)
            if let cancelButtonTitle = self.cancelButtonTitle {
                alert.addAction(UIAlertAction(title: cancelButtonTitle, style: self.cancelButtonStyle.toUIAlertActionStyle, handler: { action in
                    self.alertWindow = nil
                    cancelAction?()
                }))
            }
            if let confirmButtonTitle = self.confirmButtonTitle {
                alert.addAction(UIAlertAction(title: confirmButtonTitle, style: self.confirmButtonStyle.toUIAlertActionStyle, handler: { action in
                    self.alertWindow = nil
                    confirmAction?()
                }))
            }
            if self.alertWindow == nil { self.alertWindow = self.createAlertWindow() }
            self.alertWindow?.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }

    @available(iOS 13.0, *)
    private var windowScene: UIWindowScene? {
        return UIApplication.getInstance()?.connectedScenes.first { $0.activationState == .foregroundActive && $0 is UIWindowScene } as? UIWindowScene
    }

    private var alertWindow: UIWindow?

    private func createAlertWindow() -> UIWindow? {
        let alertWindow: UIWindow
        if #available(iOS 13.0, *) {
            if let windowScene = windowScene {
                alertWindow = UIWindow(windowScene: windowScene)
            } else {
                alertWindow = UIWindow(frame: UIScreen.main.bounds)
            }
        } else {
            alertWindow = UIWindow(frame: UIScreen.main.bounds)
        }
        alertWindow.rootViewController = UIViewController()
        alertWindow.backgroundColor = UIColor.clear
        alertWindow.windowLevel = .alert
        alertWindow.makeKeyAndVisible()
        return alertWindow
    }
}

#else

final class AlertManager: AlertManagerProtocol {
    var title: String?
    var message: String = ""
    var confirmButtonTitle: String?
    var cancelButtonTitle: String?
    var confirmButtonStyle: AlertActionStyle = .default
    var cancelButtonStyle: AlertActionStyle = .default

    init() {
        assertionFailure("Currently only UIKit version of default AlertManager is available — please provide your own implementation")
    }

    func showAlert(confirmAction: ActionCallback, cancelAction: ActionCallback) {
        assertionFailure("Currently only UIKit version of default AlertManager is available — please provide your own implementation")
    }
}

#endif
