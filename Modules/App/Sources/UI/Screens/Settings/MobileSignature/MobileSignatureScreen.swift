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

import InboxCoreUI
import InboxDesignSystem
import proton_app_uniffi
import SwiftUI

struct MobileSignatureScreen: View {
    @EnvironmentObject private var toastStateStore: ToastStateStore

    let customSettings: CustomSettingsProtocol

    var body: some View {
        StoreView(
            store: MobileSignatureStateStore(customSettings: customSettings)
        ) { state, store in
            ZStack {
                DS.Color.BackgroundInverted.norm
                    .ignoresSafeArea(edges: .all)

                VStack(spacing: DS.Spacing.extraLarge) {
                    FormSwitchView(
                        title: L10n.Settings.MobileSignature.switchLabel,
                        isOn: isEnabled(store: store)
                    )

                    if state.mobileSignature.status.isEnabled {
                        FormTextInput(
                            title: L10n.Settings.MobileSignature.textBoxLabel,
                            text: content(store: store),
                            validation: .noValidation,
                            inputType: .multiline
                        )
                    } else {
                        Spacer()
                    }
                }
                .padding(.horizontal, DS.Spacing.large)
                .padding(.bottom, DS.Spacing.extraLarge)
            }
            .navigationTitle(L10n.Settings.MobileSignature.title.string)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await store.handle(action: .onLoad)
            }
            .onChange(of: store.state.toast) { _, toast in
                if let toast {
                    toastStateStore.present(toast: toast)
                }
            }
        }
    }

    private func isEnabled(store: MobileSignatureStateStore) -> Binding<Bool> {
        .init {
            store.state.mobileSignature.status.isEnabled
        } set: { newValue in
            store.handle(action: .setIsEnabled(newValue))
        }
    }

    private func content(store: MobileSignatureStateStore) -> Binding<String> {
        .init {
            store.state.mobileSignature.body
        } set: { newValue in
            store.state = store.state.copy(\.mobileSignature.body, to: newValue)
            store.handle(action: .saveContent)
        }
    }
}

#Preview {
    NavigationStack {
        MobileSignatureScreen(customSettings: CustomSettingsPreviewProvider(status: .enabled))
    }
}
