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
import proton_app_uniffi
import SwiftUI

struct AppSettingsScreen: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject var toastStateStore: ToastStateStore
    @EnvironmentObject var appAppearanceStore: AppAppearanceStore
    @StateObject var store: AppSettingsStateStore

    init(state: AppSettingsState = .initial) {
        _store = .init(wrappedValue: .init(state: state))
    }

    var body: some View {
        ZStack {
            DS.Color.BackgroundInverted.norm
                .ignoresSafeArea(edges: .all)

            ScrollView {
                VStack(spacing: DS.Spacing.extraLarge) {
                    FormSection(header: L10n.Settings.App.deviceSectionTitle) {
                        VStack(spacing: .zero) {
                            VStack(spacing: DS.Spacing.moderatelyLarge) {
                                FormBigButton(
                                    title: L10n.Settings.App.notifications,
                                    icon: DS.SFSymbols.arrowUpRightSquare,
                                    value: store.state.areNotificationsEnabledHumanReadable.string,
                                    action: { store.handle(action: .notificationButtonTapped) }
                                )
                                FormBigButton(
                                    title: L10n.Settings.App.language,
                                    icon: DS.SFSymbols.arrowUpRightSquare,
                                    value: store.state.appLanguage,
                                    action: { store.handle(action: .languageButtonTapped) }
                                )
                                appearanceButton
                                FormBigButton(
                                    title: L10n.Settings.App.protection,
                                    icon: DS.SFSymbols.chevronRight,
                                    value: store.state.storedAppSettings.protection.humanReadable.string,
                                    action: { comingSoon() }
                                )
                            }
                            FormSection(footer: L10n.Settings.App.combinedContactsInfo) {
                                FormSwitchView(
                                    title: L10n.Settings.App.combinedContacts,
                                    isOn: combinedContactsBinding
                                )
                            }
                        }
                    }
                    FormSection(
                        header: L10n.Settings.App.mailExperience,
                        footer: L10n.Settings.App.swipeToNextEmailInfo
                    ) {
                        FormSwitchView(
                            title: L10n.Settings.App.swipeToNextEmail,
                            isOn: comingSoonBinding
                        )
                    }
                    FormSection(
                        header: L10n.Settings.App.advanced,
                        footer: L10n.Settings.App.alternativeRoutingInfo
                    ) {
                        FormSwitchView(
                            title: L10n.Settings.App.alternativeRouting,
                            isOn: alternativeRoutingBinding
                        )
                    }
                }
                .padding(.horizontal, DS.Spacing.large)
                .padding(.bottom, DS.Spacing.extraLarge)
            }
        }
        .navigationTitle(L10n.Settings.App.title.string)
        .navigationBarTitleDisplayMode(.inline)
        .onLoad {
            store.handle(action: .onLoad)
        }
        .onChange(of: scenePhase, { _, newValue in
            if newValue == .active {
                store.handle(action: .enterForeground)
            }
        })
        .onChange(of: store.state.storedAppSettings.appearance, { _, _ in
            Task {
                await appAppearanceStore.updateColorScheme()
            }
        })
    }

    @ViewBuilder
    private var appearanceButton: some View {
        Menu(
            content: {
                ForEach(AppAppearance.allCases, id: \.self) { appearance in
                    Button(action: {
                        store.handle(action: .appearanceSelected(appearance))
                    }) {
                        HStack {
                            Text(appearance.humanReadable)
                            if appearance == store.state.storedAppSettings.appearance {
                                Image(systemName: DS.SFSymbols.checkmark)
                            }
                        }
                    }
                }
            },
            label: {
                FormBigButton(
                    title: L10n.Settings.App.appearance,
                    icon: DS.SFSymbols.chevronUpChevronDown,
                    value: store.state.storedAppSettings.appearance.humanReadable.string,
                    action: { store.handle(action: .appearanceTapped) }
                )
            }
        )
    }

    private var isAppearanceMenuShown: Binding<Bool> {
        .init(
            get: { store.state.isAppearanceMenuShown },
            set: { newValue in store.state = store.state.copy(\.isAppearanceMenuShown, to: newValue) }
        )
    }

    private var combinedContactsBinding: Binding<Bool> {
        .init(
            get: { store.state.storedAppSettings.useCombineContacts },
            set: { newValue in store.handle(action: .combinedContactsChanged(newValue)) }
        )
    }

    private var alternativeRoutingBinding: Binding<Bool> {
        .init(
            get: { store.state.storedAppSettings.useAlternativeRouting },
            set: { newValue in store.handle(action: .alternativeRoutingChanged(newValue)) }
        )
    }

    private var comingSoonBinding: Binding<Bool> {
        Binding(
            get: { false },
            set: { _ in comingSoon() }
        )
    }

    private func comingSoon() {
        toastStateStore.present(toast: .comingSoon)
    }
}

#Preview {
    NavigationStack {
        AppSettingsScreen(state: .initial)
    }
}

private extension AppAppearance {

    var humanReadable: LocalizedStringResource {
        switch self {
        case .system:
            L10n.Settings.App.system
        case .darkMode:
            L10n.Settings.App.dark
        case .lightMode:
            L10n.Settings.App.light
        }
    }

    static var allCases: [Self] {
        [.system, .darkMode, .lightMode]
    }

}

private extension AppProtection {

    var humanReadable: LocalizedStringResource {
        switch self {
        case .none:
            L10n.Settings.App.none
        case .biometrics:
            switch SupportedBiometry.onDevice {
            case .faceID:
                L10n.Settings.App.faceID
            case .touchID:
                L10n.Settings.App.touchID
            case .none:
                L10n.Settings.App.none
            }
        case .pin:
            L10n.Settings.App.pinCode
        }
    }

}
