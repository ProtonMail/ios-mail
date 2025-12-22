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
import InboxCoreUI
import InboxDesignSystem
import InboxIAP
import ProtonUIFoundations
import SwiftUI
import proton_app_uniffi

struct SignaturesScreen: View {
    @EnvironmentObject private var router: Router<SettingsRoute>
    @EnvironmentObject private var toastStateStore: ToastStateStore
    @EnvironmentObject private var upsellCoordinator: UpsellCoordinator

    private let customSettings: CustomSettingsProtocol
    private let initialState: SignaturesState

    init(userSession: MailUserSession) {
        self.init(customSettings: proton_app_uniffi.customSettings(ctx: userSession))
    }

    init(customSettings: CustomSettingsProtocol, initialState: SignaturesState = .initial) {
        self.customSettings = customSettings
        self.initialState = initialState
    }

    var body: some View {
        StoreView(
            store: SignaturesStateStore(
                state: initialState,
                customSettings: customSettings,
                router: router,
                toastStateStore: toastStateStore,
                upsellPresenter: upsellCoordinator
            )
        ) { state, store in
            ZStack {
                DS.Color.BackgroundInverted.norm
                    .ignoresSafeArea(edges: .all)

                VStack(spacing: DS.Spacing.extraLarge) {
                    FormSection(footer: L10n.Settings.Signatures.AddressSignatures.footnote) {
                        FormSmallButton(
                            title: L10n.Settings.Signatures.AddressSignatures.title,
                            rightSymbol: .chevronRight,
                            action: { router.go(to: .webView(.addressSignatures)) }
                        )
                        .roundedRectangleStyle()
                    }

                    FormSection(footer: L10n.Settings.Signatures.mobileSignatureFootnote) {
                        mobileSignatureItem(status: state.mobileSignatureStatus) {
                            await store.handle(action: .mobileSignatureTapped)
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, DS.Spacing.large)
            }
            .onAppear { store.handle(action: .onAppear) }
            .sheet(item: store.binding(\.presentedUpsell), content: UpsellScreen.init)
        }
        .navigationTitle(L10n.Settings.Signatures.title.string)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func mobileSignatureItem(status: MobileSignatureStatus, action: @escaping () async -> Void) -> some View {
        FormBigButton(
            title: L10n.Settings.MobileSignature.title,
            accessoryType: .init(mobileSignatureStatus: status),
            value: status.onOffLocalized
        ) {
            Task {
                await action()
            }
        }
    }
}

private extension FormBigButton.AccessoryType {
    init(mobileSignatureStatus: MobileSignatureStatus) {
        self = mobileSignatureStatus == .needsPaidVersion ? .upsell : .symbol(.chevronRight)
    }
}

private extension MobileSignatureStatus {
    var onOffLocalized: String {
        isEnabled ? CommonL10n.on.string : CommonL10n.off.string
    }
}
