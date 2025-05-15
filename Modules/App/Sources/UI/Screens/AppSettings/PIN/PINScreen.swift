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
import InboxCoreUI
import InboxDesignSystem

struct PINScreen: View {
    private let type: PINScreenType
    private let pinVerifier: PINVerifier
    private let appProtectionConfigurator: AppProtectionConfigurator
    private let dismiss: () -> Void
    @EnvironmentObject var router: Router<PINRoute>

    init(
        type: PINScreenType,
        pinVerifier: PINVerifier = AppContext.shared.mailSession,
        appProtectionConfigurator: AppProtectionConfigurator = AppContext.shared.mailSession,
        dismiss: @escaping () -> Void
    ) {
        self.type = type
        self.pinVerifier = pinVerifier
        self.appProtectionConfigurator = appProtectionConfigurator
        self.dismiss = dismiss
    }

    var body: some View {
        StoreView(
            store: PINStateStore(
                state: .initial(type: type),
                router: router,
                pinVerifier: pinVerifier,
                appProtectionConfigurator: appProtectionConfigurator,
                dismiss: dismiss
            )
        ) { state, store in
            EnterPINView(
                title: state.type.configuration.pinInputTitle,
                text: pin(state: state, store: store),
                isInputFooterVisible: state.type.isCodeHintVisible,
                validation: validation(state: state)
            )
            .toolbar {
                leadingButton(store: store)
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { store.handle(action: .trailingButtonTapped) }) {
                        Text(state.type.configuration.trailingButtonTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(DS.Color.Text.accent)
                    }
                }
            }
            .navigationTitle(state.type.configuration.screenTitle.string)
            .navigationBarBackButtonHidden()
            .interactiveDismissDisabled(!router.stack.isEmpty)
        }
    }

    @ToolbarContentBuilder
    private func leadingButton(store: PINStateStore) -> some ToolbarContent {
        if router.stack.isEmpty {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { store.handle(action: .leadingButtonTapped) }) {
                    Text(CommonL10n.cancel)
                        .foregroundStyle(DS.Color.Text.accent)
                }
            }
        } else {
            ToolbarItemFactory.back {
                store.handle(action: .leadingButtonTapped)
            }
        }
    }

    private func pin(state: PINScreenState, store: PINStateStore) -> Binding<String> {
        .init(
            get: { state.pin },
            set: { pin in store.handle(action: .pinTyped(pin)) }
        )
    }

    private func validation(state: PINScreenState) -> Binding<FormTextInput.ValidationStatus> {
        .readonly { state.pinValidation }
    }
}
