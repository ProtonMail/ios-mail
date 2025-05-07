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
import SwiftUI

struct ConfirmPINScreen: View {
    @EnvironmentObject var router: Router<SettingsRoute>
    private let pin: String

    init(pin: String) {
        self.pin = pin
    }

    var body: some View {
        StoreView(store: ConfirmPINStore(state: .initial(pin: pin), router: router)) { state, store in
            EnterPINView(
                title: "Repeat PIN code",
                text: pin(state: state, store: store),
                validation: store.binding(\.repeatedPINValidation)
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { store.handle(action: .confirmButtonTapped) }) {
                        Text("Confirm")
                            .fontWeight(.bold)
                            .foregroundStyle(DS.Color.Text.accent)
                    }
                }
            }
            .navigationTitle("Repeat PIN code")
        }
    }

    private func pin(state: ConfirmPINState, store: ConfirmPINStore) -> Binding<String> {
        .init(
            get: { state.pin },
            set: { pin in store.handle(action: .pinTyped(pin)) }
        )
    }
}

#Preview {
    NavigationStack {
        ConfirmPINScreen(pin: .empty)
    }
}
