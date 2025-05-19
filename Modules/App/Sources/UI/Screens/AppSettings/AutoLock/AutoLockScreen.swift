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

struct AutoLockScreen: View {
    private let initialState: AutoLockState
    private let appSettingsRepository: AppSettingsRepository
    @EnvironmentObject var router: Router<SettingsRoute>

    init(
        state: AutoLockState = .init(),
        appSettingsRepository: AppSettingsRepository = AppContext.shared.mailSession
    ) {
        self.initialState = state
        self.appSettingsRepository = appSettingsRepository
    }

    var body: some View {
        StoreView(
            store: AutoLockStore(
                state: initialState,
                appSettingsRepository: appSettingsRepository,
                router: router
            )
        ) { state, store in
            ScrollView {
                FormList(collection: state.allOptions) { lockOption in
                    FormSmallButton(
                        title: lockOption.humanReadable,
                        rightSymbol: state.selectedOption == lockOption ? .checkmark : nil
                    ) {
                        store.handle(action: .optionSelected(lockOption))
                    }
                }
                .padding(DS.Spacing.large)
            }
            .navigationTitle(L10n.Settings.App.autoLock.string)
            .navigationBarTitleDisplayMode(.inline)
            .background(DS.Color.BackgroundInverted.norm)
            .onLoad { store.handle(action: .onLoad) }
        }
    }
}
