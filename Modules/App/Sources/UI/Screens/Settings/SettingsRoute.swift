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

import InboxCore
import InboxDesignSystem
import proton_app_uniffi
import SwiftUI
import Combine

enum SettingsRoute: Routable {
    case webView(ProtonAuthenticatedWebPage)
    case appSettings
    case appProtection

    @MainActor @ViewBuilder
    func view() -> some View {
        switch self {
        case .webView(let webPage):
            ProtonAuthenticatedWebView(webViewPage: webPage)
                .background(DS.Color.BackgroundInverted.norm)
                .edgesIgnoringSafeArea(.bottom)
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(webPage.title.string)
                .navigationBarBackButtonHidden(true)
        case .appSettings:
            AppSettingsScreen()
        case .appProtection:
            AppProtectionSelectionScreen()
        }
    }
}

private extension ProtonAuthenticatedWebPage {

    var title: LocalizedStringResource {
        switch self {
        case .accountSettings:
            L10n.Settings.account
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
