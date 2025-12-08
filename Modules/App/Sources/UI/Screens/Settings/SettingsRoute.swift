// Copyright (c) 2025 Proton Technologies AG
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

import AccountLogin
import AccountPassword
import Combine
import InboxCore
import InboxIAP
import SwiftUI
import proton_app_uniffi

enum SettingsRoute: Routable {
    case webView(ProtonAuthenticatedWebPage)
    case appSettings
    case appProtection
    case autoLock
    case mobileSignature
    case scanQRCode
    case signatures
    case changePassword(PasswordChange.State)
    case customizeToolbars
    case securityKeys(UserSettings)
    case subscription

    var isChangePassword: Bool {
        switch self {
        case .changePassword:
            true
        default:
            false
        }
    }
}

struct SettingsViewFactory {
    let mailUserSession: MailUserSession
    let accountAuthCoordinator: AccountAuthCoordinator
    let upsellCoordinator: UpsellCoordinator

    @MainActor @ViewBuilder
    func makeView(for route: SettingsRoute) -> some View {
        switch route {
        case .webView(let webPage):
            ProtonAuthenticatedWebView(webViewPage: webPage, upsellCoordinator: upsellCoordinator)
                .edgesIgnoringSafeArea(.bottom)
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(webPage.title.string)
                .navigationBarBackButtonHidden(true)
        case .appSettings:
            AppSettingsScreen(customSettings: customSettings(ctx: mailUserSession))
        case .appProtection:
            AppProtectionSelectionScreen()
        case .autoLock:
            AutoLockScreen()
        case .mobileSignature:
            MobileSignatureScreen(customSettings: customSettings(ctx: mailUserSession))
        case .scanQRCode:
            ScanQRCodeInstructionsView(
                viewModel: .init(dependencies: .init(mailUserSession: mailUserSession, productName: AppDetails.mail.product))
            )
            .navigationBarTitleDisplayMode(.inline)
        case .changePassword(let state):
            PasswordChange.view(from: state)
        case .securityKeys(let userSettings):
            accountAuthCoordinator.securityKeyListView(userSettings: userSettings)
        case .signatures:
            SignaturesScreen(userSession: mailUserSession)
        case .subscription:
            AvailablePlansViewFactory.make(mailUserSession: mailUserSession, presentationMode: .push)
        case .customizeToolbars:
            CustomizeToolbarsScreen(customizeToolbarService: mailUserSession, viewModeProvider: mailUserSession)
        }
    }
}

private extension ProtonAuthenticatedWebPage {
    var title: LocalizedStringResource {
        switch self {
        case .accountSettings:
            L10n.Settings.account
        case .addressSignatures:
            L10n.Settings.Signatures.AddressSignatures.title
        case .emailSettings:
            L10n.Settings.email
        case .spamFiltersSettings:
            L10n.Settings.filters
        case .privacySecuritySettings:
            L10n.Settings.privacyAndSecurity
        case .createFolderOrLabel:
            L10n.Settings.foldersAndLabels
        }
    }
}
