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

struct AppProtectionSelectionScreen: View {
    private let state: AppProtectionSelectionState
    private let appSettingsRepository: AppSettingsRepository
    @EnvironmentObject var settingsRouter: Router<SettingsRoute>

    init(
        state: AppProtectionSelectionState = .initial,
        appSettingsRepository: AppSettingsRepository = AppContext.shared.mailSession
    ) {
        self.state = state
        self.appSettingsRepository = appSettingsRepository
    }

    var body: some View {
        StoreView(
            store: AppProtectionSelectionStore(
                state: state,
                router: settingsRouter,
                appSettingsRepository: appSettingsRepository
            )
        ) { state, store in
            ScrollView {
                VStack(spacing: .zero) {
                    FormSection(footer: L10n.Settings.App.protectionSelectionListFooterInformation) {
                        FormList(collection: state.availableAppProtectionMethods) { viewModel in
                            FormSmallButton(
                                title: viewModel.type.name,
                                rightSymbol: viewModel.isSelected ? .checkmark : nil
                            ) {
                                store.handle(action: .selected(viewModel.type))
                            }
                        }
                    }
                    if state.shouldShowChangePasswordButton {
                        FormSection {
                            FormSmallButton(title: L10n.Settings.App.changePINcode, rightSymbol: .chevronRight) {
                                // FIXME: - Trigger set new password flow
                            }
                            .applyRoundedRectangleStyle()
                        }
                    }
                    Spacer()
                }.animation(.easeInOut, value: state.shouldShowChangePasswordButton)
            }
            .padding(.horizontal, DS.Spacing.large)
            .background(DS.Color.BackgroundInverted.norm)
            .navigationTitle(L10n.Settings.App.protectionSelectionScreenTitle.string)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { store.handle(action: .onAppear) }
            .sheet(item: store.binding(\.pinScreen)) { pinScreenType in
                PINRouterView(type: pinScreenType)
            }
        }
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
                    .init(type: .faceID, isSelected: true),
                ]
            ),
            appSettingsRepository: MailSession(noPointer: .init())
        )
    }
}

private extension AppProtectionSelectionState {

    var shouldShowChangePasswordButton: Bool {
        selectedAppProtection == .pin
    }

}
