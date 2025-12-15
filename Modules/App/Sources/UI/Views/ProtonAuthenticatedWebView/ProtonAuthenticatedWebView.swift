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

import InboxCoreUI
import InboxDesignSystem
import InboxIAP
import SwiftUI

struct ProtonAuthenticatedWebView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @StateObject private var model: ProtonAuthenticatedWebModel

    init(webViewPage: ProtonAuthenticatedWebPage, upsellCoordinator: UpsellCoordinator?) {
        _model = .init(wrappedValue: ProtonAuthenticatedWebModel(webViewPage: webViewPage, upsellCoordinator: upsellCoordinator))
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
            .fullScreenCover(item: $model.presentedUpsell, content: UpsellScreen.init)
    }
}

extension ProtonAuthenticatedWebView {
    @ViewBuilder
    private var viewForState: some View {
        switch model.state {
        case .forkingSession:
            ProgressView()
        case .urlReady(let url):
            VStack(alignment: .leading, spacing: 11) {
                WebView(url: url, configureUserContentController: model.setupUpsellScreenCapability)
                    .accessibilityIdentifier(ProtonAuthenticatedWebViewIdentifiers.webView)
            }
            .accessibilityElement(children: .contain)
            .background(DS.Color.BackgroundInverted.norm)
        case .error(let error):
            ErrorView(error: error)
        }
    }
}

private struct ProtonAuthenticatedWebViewIdentifiers {
    static let webView = "webView.rootItem"
}
