//
//  PaymentsUIAlertManager.swift
//  ProtonCorePaymentsUI - Created on 19/08/2021.
//
//  Copyright (c) 2022 Proton Technologies AG
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

#if os(iOS)

import Foundation
import ProtonCorePayments
import ProtonCoreUIFoundations

protocol PaymentsUIAlertManager: AlertManagerProtocol {
    var viewController: PaymentsUIViewController? { get set }
    var delegatedAlertManager: AlertManagerProtocol { get }
    func showError(message: String, error: Error?, action: ActionCallback)
}

extension PaymentsUIAlertManager {
    func passAlertToDelegatedManager(confirmAction: ActionCallback, cancelAction: ActionCallback) {
        delegatedAlertManager.title = title
        delegatedAlertManager.message = message
        delegatedAlertManager.confirmButtonTitle = confirmButtonTitle
        delegatedAlertManager.cancelButtonTitle = cancelButtonTitle
        delegatedAlertManager.confirmButtonStyle = confirmButtonStyle
        delegatedAlertManager.cancelButtonStyle = cancelButtonStyle
        delegatedAlertManager.showAlert(confirmAction: confirmAction, cancelAction: cancelAction)
    }

    func showErrorOnDelegatedManager(message: String) {
        delegatedAlertManager.title = nil
        delegatedAlertManager.message = message
        delegatedAlertManager.confirmButtonTitle = PUITranslations._core_ok_button.l10n
        delegatedAlertManager.cancelButtonTitle = nil
        delegatedAlertManager.confirmButtonStyle = .cancel
        delegatedAlertManager.cancelButtonStyle = .default
        delegatedAlertManager.showAlert(confirmAction: {}, cancelAction: nil)
    }
}

final class LocallyPresentingPaymentsUIAlertManager: PaymentsUIAlertManager {

    weak var viewController: PaymentsUIViewController?
    let delegatedAlertManager: AlertManagerProtocol

    var title: String?
    var message: String = ""
    var confirmButtonTitle: String?
    var cancelButtonTitle: String?
    var confirmButtonStyle: AlertActionStyle = .default
    var cancelButtonStyle: AlertActionStyle = .default

    init(delegatedAlertManager: AlertManagerProtocol) {
        self.delegatedAlertManager = delegatedAlertManager
    }

    func showAlert(confirmAction: ActionCallback, cancelAction: ActionCallback) {
        guard confirmButtonTitle == nil || cancelButtonTitle == nil else {
            // banner cannot show two buttons at the same time — pass this alert out
            passAlertToDelegatedManager(confirmAction: confirmAction, cancelAction: cancelAction)
            return
        }
        showError(message: message, action: confirmAction ?? cancelAction)
    }

    func showError(message: String, error: Error? = nil, action: ActionCallback = nil) {
        guard let viewController = viewController else { return }
        if !viewController.activityIndicator.isHidden {
            viewController.activityIndicator.isHidden = true
        }
        // show overlay error in case of internet connection issue
        if let error = error, (error as NSError).isNetworkIssueError || error.httpCode == 505 {
            viewController.showOverlayConnectionError()
        } else {
            let banner = PMBanner(message: message, style: PMBannerNewStyle.error, dismissDuration: Double.infinity)
            banner.addButton(text: PUITranslations._core_ok_button.l10n) {
                $0.dismiss()
                action?()
            }
            viewController.showBanner(banner: banner, position: .top)
        }
    }
}

final class AlwaysDelegatingPaymentsUIAlertManager: PaymentsUIAlertManager {

    weak var viewController: PaymentsUIViewController?
    let delegatedAlertManager: AlertManagerProtocol

    var title: String?
    var message: String = ""
    var confirmButtonTitle: String?
    var cancelButtonTitle: String?
    var confirmButtonStyle: AlertActionStyle = .default
    var cancelButtonStyle: AlertActionStyle = .default

    init(delegatedAlertManager: AlertManagerProtocol) {
        self.delegatedAlertManager = delegatedAlertManager
    }

    func showAlert(confirmAction: ActionCallback, cancelAction: ActionCallback) {
        passAlertToDelegatedManager(confirmAction: confirmAction, cancelAction: cancelAction)
    }

    func showError(message: String, error: Error?, action: ProtonCorePayments.ActionCallback) {
        showErrorOnDelegatedManager(message: message)
    }
}

#endif
