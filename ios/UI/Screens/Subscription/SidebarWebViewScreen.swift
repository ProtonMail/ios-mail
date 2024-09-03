// Copyright (c) 2024 Proton Technologies AG
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

import DesignSystem
import SwiftUI

struct SidebarWebViewScreen: View {
    private let webViewPage: ProtonAuthenticatedWebPage

    init(webViewPage: ProtonAuthenticatedWebPage) {
        self.webViewPage = webViewPage
    }

    var body: some View {
        ClosableScreen {
            ProtonAuthenticatedWebView(webViewPage: webViewPage)
                .background(DS.Color.Background.norm)
                .edgesIgnoringSafeArea(.bottom)
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(webViewPage.title.string)
				.accessibilityElement()
                .accessibilityIdentifier(SidebarWebViewScreenIdentifiers.rootItem(forPage: webViewPage))
        }
    }
}

private extension ProtonAuthenticatedWebPage {

    var title: LocalizedStringResource {
        switch self {
        case .accountSettings:
            L10n.Settings.accountSettings
        case .createFolderOrLabel:
            L10n.CreateFolderOrLabel.title
        case .emailSettings, .privacySecuritySettings, .spamFiltersSettings:
            fatalError("Not implemented")
        }
    }

}

private struct SidebarWebViewScreenIdentifiers {
    static func rootItem(forPage page: ProtonAuthenticatedWebPage) -> String {
        "sheet.\(page.action).rootItem"
    }
}
