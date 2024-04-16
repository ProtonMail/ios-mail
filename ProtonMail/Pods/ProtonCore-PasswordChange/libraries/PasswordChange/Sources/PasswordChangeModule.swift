//
//  PasswordChangeModule.swift
//  ProtonCore-PasswordChange - Created on 20.03.2024.
//
//  Copyright (c) 2024 Proton Technologies AG
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

import Foundation
import SwiftUI
import ProtonCoreDataModel
import ProtonCoreFeatureFlags
import ProtonCoreNetworking
import ProtonCoreUIFoundations
import ProtonCoreServices

#if os(iOS)
public typealias PasswordChangeViewController = UIHostingController<PasswordChangeView>
public typealias PasswordChangeCompletion = (_ authCredential: AuthCredential, _ userInfo: UserInfo) -> Void

/// Useful parameters to have handy
public enum PasswordChangeModule {
    /// Feature switch that governs the PasswordChange initiative
    public static let feature = CoreFeatureFlagType.changePassword

    /// Mode of the password change
    public enum PasswordChangeMode {
        /// Use `singlePassword` when the account does not have a Mailbox password or want to change both passwords.
        case singlePassword
        /// Use `loginPassword` when the account has a Mailbox password and want to change the Login password.
        case loginPassword
        /// Use `mailboxPassword` when the account has a Mailbox password and want to change it.
        case mailboxPassword
    }

    /// Resource bundle for the Password Change module
    public static var resourceBundle: Bundle {
        #if SWIFT_PACKAGE
        let resourceBundle = Bundle.module
        return resourceBundle
        #else
        let podBundle = Bundle(for: PasswordChangeClass.self)
        if let bundleURL = podBundle.url(forResource: "Resources-PasswordChange", withExtension: "bundle") {
            if let bundle = Bundle(url: bundleURL) {
                return bundle
            }
        }
        return podBundle
        #endif
    }
    
    /// Localized name of the settings item for Password Change
    public static let settingsItem = PCTranslation.settingsItem.l10n

    /// Method to obtain the PasswordChangeViewController
    ///
    /// - Parameters:
    ///    - mode: Type of password you want to change. Refer to ``PasswordChangeMode``.
    ///    - apiService: APIService implementation of the client.
    ///    - authCredential: Current credential session
    ///    - userInfo: User information got from Get user's info request: https://protonmail.gitlab-pages.protontech.ch/Slim-API/core/#tag/Users/operation/get_core-%7B_version%7D-users
    /// - Returns: Starting ViewController of the PasswordChange flow.
    @MainActor
    public static func makePasswordChangeViewController(
        mode: PasswordChangeMode,
        apiService: APIService,
        authCredential: AuthCredential,
        userInfo: UserInfo,
        completion: PasswordChangeCompletion?
    ) -> PasswordChangeViewController {
        let passwordChangeService = PasswordChangeService(api: apiService)
        let viewModel = PasswordChangeView.ViewModel(
            mode: mode,
            passwordChangeService: passwordChangeService,
            authCredential: authCredential,
            userInfo: userInfo,
            passwordChangeCompletion: completion
        )
        let viewController = UIHostingController(rootView: PasswordChangeView(viewModel: viewModel))
        viewController.view.backgroundColor = ColorProvider.BackgroundNorm
        Self.initialViewController = viewController
        return viewController
    }

    weak static var initialViewController: UIViewController?
}

private class PasswordChangeClass {}
#endif
