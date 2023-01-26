//
//  ForceUpgradeController.swift
//  ProtonCore-ForceUpgrade - Created on 23/10/20.
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

import UIKit
import ProtonCore_CoreTranslation
import protocol ProtonCore_Networking.ForceUpgradeResponseDelegate
import ProtonCore_UIFoundations

extension ForceUpgradeHelper {
    public convenience init(config: ForceUpgradeConfig, responseDelegate: ForceUpgradeResponseDelegate? = nil) {
        self.init(config: config, controller: ForceUpgradeControllerForUIKit(), responseDelegate: responseDelegate)
    }
}

final class ForceUpgradeControllerForUIKit: ForceUpgradeController {
    fileprivate var config: ForceUpgradeConfig?
    fileprivate weak var responseDelegate: ForceUpgradeResponseDelegate?
    fileprivate var alert: UIAlertController!

    func performForceUpgrade(message: String, config: ForceUpgradeConfig, responseDelegate: ForceUpgradeResponseDelegate?) {

        self.config = config
        self.responseDelegate = responseDelegate

        let buttonTitle: String
        switch config {
        case .mobile: buttonTitle = CoreString._fu_alert_learn_more_button
        case .desktop: buttonTitle = CoreString._fu_alert_quit_button
        }

        alert = UIAlertController(title: CoreString._fu_alert_title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: buttonTitle, style: .default, handler: { _ in
            secondaryButtonAction()
            self.alertWindow?.rootViewController?.present(self.alert, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: CoreString._fu_alert_update_button, style: .default, handler: { _ in
            primaryButtonAction()
            self.alertWindow?.rootViewController?.present(self.alert, animated: true, completion: nil)
        }))
        alertWindow?.rootViewController?.present(alert, animated: true, completion: nil)

        func secondaryButtonAction() {
            if case .mobile = config {
                guard let url = URL(string: "https://proton.me/support/update-required") else { return }
                UIApplication.openURLIfPossible(url)
            } else if case .desktop = config {
                responseDelegate?.onQuitButtonPressed()
            }
        }

        func primaryButtonAction() {
            responseDelegate?.onUpdateButtonPressed()
            guard case .mobile(let url) = config else { return }
            if UIApplication.getInstance()?.canOpenURL(url) == true {
                UIApplication.openURLIfPossible(url)
            }
        }
    }

    @available(iOS 13.0, *)
    private var windowScene: UIWindowScene? {
        return UIApplication.getInstance()?.connectedScenes.first { $0.activationState == .foregroundActive && $0 is UIWindowScene } as? UIWindowScene
    }

    private lazy var alertWindow: UIWindow? = {
        let alertWindow: UIWindow?
        if #available(iOS 13.0, *) {
            if let windowScene = windowScene {
                alertWindow = UIWindow(windowScene: windowScene)
            } else {
                alertWindow = UIWindow(frame: UIScreen.main.bounds)
            }
        } else {
            alertWindow = UIWindow(frame: UIScreen.main.bounds)
        }
        alertWindow?.rootViewController = UIViewController()
        alertWindow?.backgroundColor = UIColor.clear
        alertWindow?.windowLevel = .alert
        alertWindow?.makeKeyAndVisible()
        return alertWindow
    }()
}
