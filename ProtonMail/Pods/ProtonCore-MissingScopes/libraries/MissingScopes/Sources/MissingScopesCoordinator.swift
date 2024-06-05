//
//  MissingScopesCoordinator.swift
//  ProtonCore-MissingScopes - Created on 27.04.23.
//
//  Copyright (c) 2023 Proton Technologies AG
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

#if os(iOS)

import UIKit
import ProtonCoreAuthentication
import ProtonCoreServices
import ProtonCoreUIFoundations
import ProtonCoreFoundations
import ProtonCorePasswordRequest

public protocol MissingScopesCoordinatorDelegate: AnyObject {
    func showAskPassword()
}

public class MissingScopesCoordinator: MissingScopesCoordinatorDelegate {
    private let apiService: APIService
    private let username: String
    private let missingScopeMode: MissingScopeMode
    private let inAppTheme: () -> InAppTheme
    private let responseHandlerData: PMResponseHandlerData
    private let completion: (MissingScopesFinishReason) -> Void
    private var passwordVerifierViewController: PasswordVerifierViewController?

    init(apiService: APIService,
         username: String,
         missingScopeMode: MissingScopeMode,
         inAppTheme: @escaping () -> InAppTheme = { .default },
         responseHandlerData: PMResponseHandlerData,
         completion: @escaping (MissingScopesFinishReason) -> Void
    ) {
        self.apiService = apiService
        self.username = username
        self.missingScopeMode = missingScopeMode
        self.inAppTheme = inAppTheme
        self.responseHandlerData = responseHandlerData
        self.completion = completion
    }

    public func showAskPassword() {
        let passwordVerifierViewController = setupPasswordVerifierViewController()
        self.passwordVerifierViewController = passwordVerifierViewController

        let nav = DarkModeAwareNavigationViewController()
        nav.overrideUserInterfaceStyle = inAppTheme().userInterfaceStyle
        nav.viewControllers = [passwordVerifierViewController]

        var topViewController: UIViewController?
        let keyWindow = UIApplication.firstKeyWindow
        if var top = keyWindow?.rootViewController {
            while let presentedViewController = top.presentedViewController {
                top = presentedViewController
            }
            topViewController = top
        }

        topViewController?.present(nav, animated: true)
    }

    private func setupPasswordVerifierViewController() -> PasswordVerifierViewController {
        let passwordVerifierViewController = PasswordVerifierViewController()
        passwordVerifierViewController.delegate = self
        passwordVerifierViewController.viewModel = PasswordVerifier(
            apiService: apiService,
            username: username,
            endpoint: UnlockEndpoint(),
            missingScopeMode: missingScopeMode,
            responseHandlerData: responseHandlerData
        )
        passwordVerifierViewController.overrideUserInterfaceStyle = inAppTheme().userInterfaceStyle
        return passwordVerifierViewController
    }
}

extension MissingScopesCoordinator: PasswordVerifierViewControllerDelegate {
    public func didShowWrongPassword() {
        // noop
    }
    
    public func userUnlocked() {
        completion(.unlocked)
    }

    public func didCloseVerifyPassword() {
        completion(.closed)
    }

    public func didCloseWithError(code: Int, description: String) {
        completion(.closedWithError(code: code, description: description))
    }
}

#endif
