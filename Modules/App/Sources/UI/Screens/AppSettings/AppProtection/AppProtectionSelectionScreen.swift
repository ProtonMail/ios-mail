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

import InboxDesignSystem
import proton_app_uniffi
import SwiftUI

struct AppProtectionSelectionScreen: View {
    @StateObject var store: AppProtectionSelectionStore

    init(state: AppProtectionSelectionState) {
        _store = .init(wrappedValue: .init(state: state))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: .zero) {
                FormSection(footer: "All protection settings will be reset and wiped upon signing out of the app") {
                    FormList(collection: store.state.availableAppProtectionMethods) { viewModel in
                        FormSmallButton(
                            title: viewModel.type.name,
                            rightSymbol: viewModel.isSelected ? .checkmark : nil
                        ) {
                            store.handle(action: .selected(viewModel.type))
                        }
                    }
                }
                Spacer()
            }
        }
        .padding(.horizontal, DS.Spacing.large)
        .background(DS.Color.BackgroundInverted.norm)
        .navigationTitle("Protection")
        .navigationBarTitleDisplayMode(.inline)
    }

}

#Preview {
    NavigationStack {
        AppProtectionSelectionScreen(
            state: .init(
                selectedAppProtection: .biometrics,
                availableAppProtectionMethods: [
                    .init(type: .none, isSelected: false),
                    .init(type: .pin, isSelected: false),
                    .init(type: .faceID, isSelected: true)
                ]
            )
        )
    }
}

private extension FormSmallButton.Symbol {

    static var checkmark: Self {
        .init(name: DS.SFSymbols.checkmark, color: DS.Color.Icon.accent)
    }

}
