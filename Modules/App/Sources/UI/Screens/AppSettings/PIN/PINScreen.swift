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

import SwiftUI
import InboxCore
import InboxDesignSystem

struct PINScreen: View {
    private let type: PINScreenType
    @EnvironmentObject var router: Router<SettingsRoute>

    init(type: PINScreenType) {
        self.type = type
    }

    var body: some View {
        StoreView(
            store: PINStateStore(state: .initial(type: type), router: router)
        ) { state, store in
            EnterPINView(
                title: state.type.configuration.pinInputTitle,
                text: pin(state: state, store: store),
                validation: validation(state: state)
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { store.handle(action: .trailingButtonTapped) }) {
                        Text(state.type.configuration.trailingButtonTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(DS.Color.Text.accent)
                    }
                }
            }
            .navigationTitle(state.type.configuration.screenTitle.string)
        }
    }

    private func pin(state: PINScreenState, store: PINStateStore) -> Binding<String> {
        .init(
            get: { state.pin },
            set: { pin in store.handle(action: .pinTyped(pin)) }
        )
    }

    private func validation(state: PINScreenState) -> Binding<FormTextInput.ValidationStatus> {
        .init(
            get: { state.pinValidation },
            set: { _ in }
        )
    }

}
