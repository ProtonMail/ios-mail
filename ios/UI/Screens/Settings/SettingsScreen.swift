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

struct SettingsScreen: View {
    @EnvironmentObject private var appUIState: AppUIState

    var body: some View {
        NavigationStack {
            Form {
                Section(
                    header: EmptyView(),
                    content: {
                        NavigationLink(L10n.Settings.accountSettings.string) {
                            ZIndexUpdateContainer(zIndex: $appUIState.sidebarZIndex) {
                                AccountSettingsScreen()
                            }
                        }
                        .navigationBarTitleDisplayMode(.inline)
                        .mainToolbar(title: L10n.Settings.title)
                        .toolbarBackground(.visible, for: .navigationBar)
                    })
            }
            .scrollContentBackground(.hidden)
            .background(DS.Color.Background.secondary)
        }
    }
}
