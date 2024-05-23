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

struct SubscriptionScreen: View {
    @StateObject private var model: SubscriptionModel = .init()

    var body: some View {
        NavigationStack {
            viewForState
                .navigationBarTitleDisplayMode(.inline)
                .mainToolbar(title: LocalizationTemp.Settings.subscription)
        }
        .task {
            model.generateSubscriptionUrl()
        }
        .onDisappear {
            model.pollEvents()
        }
    }
}

extension SubscriptionScreen {

    @ViewBuilder
    private var viewForState: some View {
        switch model.state {
        case .forkingSession:
            ProgressView()
        case .urlReady(let url):
            VStack(alignment: .leading, spacing: 11) {
                WebView(url: url)
                    .edgesIgnoringSafeArea(.all)
            }
        case .error(let error):
            Text(String(describing: error))
        }
    }
}
