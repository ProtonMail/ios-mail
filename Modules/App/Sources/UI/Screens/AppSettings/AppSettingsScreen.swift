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
import ProtonUIFoundations
import SwiftUI
import proton_app_uniffi

struct AppSettingsScreen: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject var appAppearanceStore: AppAppearanceStore
    @EnvironmentObject var router: Router<SettingsRoute>
    @StateObject var store: AppSettingsStateStore
    private let appIconConfigurator: AppIconConfigurable

    init(
        state: AppSettingsState? = .none,
        appSettingsRepository: AppSettingsRepository = AppContext.shared.mailSession,
        customSettings: CustomSettingsProtocol,
        appIconConfigurator: AppIconConfigurable = UIApplication.shared,
    ) {
        _store = .init(
            wrappedValue: .init(
                state: state ?? .initial(appIconName: appIconConfigurator.alternateIconName),
                appSettingsRepository: appSettingsRepository,
                customSettings: customSettings,
                appIconConfigurator: appIconConfigurator
            )
        )
        self.appIconConfigurator = appIconConfigurator
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
                                    symbol: .arrowUpRightSquare,
                                    value: store.state.areNotificationsEnabledHumanReadable.string,
                                    action: { store.handle(action: .notificationButtonTapped) }
                                )
                                FormBigButton(
                                    title: L10n.Settings.App.language,
                                    symbol: .arrowUpRightSquare,
                                    value: store.state.appLanguage,
                                    action: { store.handle(action: .languageButtonTapped) }
                                )
                                appearanceButton
                                FormBigButton(
                                    title: L10n.Settings.App.appLock,
                                    symbol: .chevronRight,
                                    value: store.state.storedAppSettings.protection.humanReadable.string,
                                    action: { router.go(to: .appProtection) }
                                )
                                if appIconConfigurator.supportsAlternateIcons {
                                    appIconButton
                                }
                            }
                            FormSection(footer: L10n.Settings.App.combinedContactsInfo) {
                                FormSwitchView(
                                    title: L10n.Settings.App.combinedContacts,
                                    isOn: useCombinedContacts
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
                            isOn: isSwipeToAdjacentConversation
                        )
                    }
                    FormSection(header: nil, footer: nil) {
                        FormSmallButton(
                            title: L10n.Settings.App.customizeToolbars,
                            rightSymbol: .chevronRight
                        ) {
                            router.go(to: .customizeToolbars)
                        }
                        .roundedRectangleStyle()
                    }
                    FormSection(
                        header: L10n.Settings.App.advanced,
                        footer: L10n.Settings.App.alternativeRoutingInfo
                    ) {
                        FormSwitchView(
                            title: L10n.Settings.App.alternativeRouting,
                            isOn: isAlternativeRoutingEnabled
                        )
                    }
                }
                .padding(.horizontal, DS.Spacing.large)
                .padding(.bottom, DS.Spacing.extraLarge)
            }
        }
        .navigationTitle(L10n.Settings.App.title.string)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { store.handle(action: .onAppear) }
        .onChange(
            of: scenePhase,
            { _, newValue in
                if newValue == .active {
                    store.handle(action: .enterForeground)
                }
            }
        )
        .onChange(
            of: store.state.storedAppSettings.appearance,
            { _, _ in
                Task {
                    await appAppearanceStore.updateColorScheme()
                }
            }
        )
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
                                Image(symbol: .checkmark)
                            }
                        }
                    }
                }
            },
            label: {
                FormBigButton(
                    title: L10n.Settings.App.appearance,
                    symbol: .chevronUpChevronDown,
                    value: store.state.storedAppSettings.appearance.humanReadable.string,
                    action: { store.handle(action: .appearanceTapped) }
                )
            }
        )
    }

    @ViewBuilder
    private var appIconButton: some View {
        Menu(
            content: {
                ForEach(AppIcon.allCases.filter { icon in store.state.appIcon != icon }, id: \.self) { icon in
                    Button(action: { store.handle(action: .appIconSelected(icon)) }) {
                        HStack(spacing: DS.Spacing.medium) {
                            Text(icon.title)
                            Image(icon.preview)
                        }
                    }
                }
            },
            label: {
                FormBigButton(
                    title: L10n.Settings.AppIcon.buttonTitle,
                    symbol: .chevronUpChevronDown,
                    value: store.state.appIcon.title.string,
                    action: {}
                )
            }
        )
    }

    private var useCombinedContacts: Binding<Bool> {
        .init(
            get: { store.state.storedAppSettings.useCombineContacts },
            set: { newValue in store.handle(action: .combinedContactsChanged(newValue)) }
        )
    }

    private var isAlternativeRoutingEnabled: Binding<Bool> {
        .init(
            get: { store.state.storedAppSettings.useAlternativeRouting },
            set: { newValue in store.handle(action: .alternativeRoutingChanged(newValue)) }
        )
    }

    private var isSwipeToAdjacentConversation: Binding<Bool> {
        .init(
            get: { store.state.isSwipeToAdjacentConversationEnabled },
            set: { newValue in store.handle(action: .swipeToAdjacentConversationChanged(newValue)) }
        )
    }
}

#Preview {
    NavigationStack {
        AppSettingsScreen(state: .initial(appIconName: .none), customSettings: CustomSettings(noPointer: .init()))
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
            switch SupportedBiometry.configuredOnDevice() {
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
