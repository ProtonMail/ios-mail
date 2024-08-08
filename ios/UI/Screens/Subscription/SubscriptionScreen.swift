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

struct ProtonAuthenticatedWebView_v2: View {
    @Environment (\.colorScheme) var colorScheme: ColorScheme
    @StateObject private var model: ProtonAuthenticatedWebModel

    init(model: ProtonAuthenticatedWebModel) {
        self._model = .init(wrappedValue: model)
    }

    var body: some View {
        viewForState
            .task {
                model.generateSubscriptionUrl(colorScheme: colorScheme)
            }
            .onChange(of: colorScheme) { _, newValue in
                model.generateSubscriptionUrl(colorScheme: newValue)
            }
            .onDisappear {
                model.pollEvents()
            }
    }
}

extension ProtonAuthenticatedWebView_v2 {

    @ViewBuilder
    private var viewForState: some View {
        switch model.state {
        case .forkingSession:
            ProgressView()
        case .urlReady(let url):
            VStack(alignment: .leading, spacing: 11) {
                WebView(url: url)
                    .accessibilityIdentifier(SubscriptionScreenIdentifiers.webView)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(SubscriptionScreenIdentifiers.rootItem)
        case .error(let error):
            Text(String(describing: error))
        }
    }
}

private struct SubscriptionScreenIdentifiers {
    static let rootItem = "subscription.rootItem"
    static let webView = "subscription.webView"
}


struct SidebarWebViewScreen: View {

    @EnvironmentObject var appUIState: AppUIState
    private let webViewPage: ProtonAuthenticatedWebPage
    private let webViewModel: ProtonAuthenticatedWebModel

    init(webViewPage: ProtonAuthenticatedWebPage) {
        self.webViewPage = webViewPage
        self.webViewModel = .init(webViewPage: webViewPage)
    }

    var body: some View {
        NavigationStack {
            ProtonAuthenticatedWebView_v2(model: webViewModel)
                .background(DS.Color.Background.norm)
                .edgesIgnoringSafeArea(.bottom)
                .navigationBarTitleDisplayMode(.inline)
                .mainToolbar(title: webViewPage.title)
                .onChange(of: appUIState.isSidebarOpen) {
                    if appUIState.isSidebarOpen {
                        webViewModel.pollEvents()
                    }
                }
        }
    }

}

private extension ProtonAuthenticatedWebPage {

    var title: LocalizedStringResource {
        switch self {
        case .mailSettings:
            L10n.Settings.accountSettings
        case .subscriptionDetails:
            L10n.Settings.subscription
        case .createFolder:
            L10n.Sidebar.createFolder
        case .createLabel:
            L10n.Sidebar.createLabel
        }
    }

}
