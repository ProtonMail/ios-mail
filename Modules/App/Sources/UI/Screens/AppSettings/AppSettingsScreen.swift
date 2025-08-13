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
import proton_app_uniffi
import SwiftUI

struct AppSettingsScreen: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject var toastStateStore: ToastStateStore
    @EnvironmentObject var appAppearanceStore: AppAppearanceStore
    @EnvironmentObject var router: Router<SettingsRoute>
    @EnvironmentObject private var upsellCoordinator: UpsellCoordinator
    @StateObject var store: AppSettingsStateStore

    init(
        state: AppSettingsState = .initial,
        appSettingsRepository: AppSettingsRepository = AppContext.shared.mailSession
    ) {
        _store = .init(
            wrappedValue: .init(
                state: state,
                appSettingsRepository: appSettingsRepository
            )
        )
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
                    if CustomizeToolbarsFlag.isVisible {
                        FormSection(header: nil, footer: nil) {
                            FormSmallButton(
                                title: L10n.Settings.App.customizeToolbars,
                                rightSymbol: .chevronRight
                            ) {
                                router.go(to: .customizeToolbars)
                            }
                            .roundedRectangleStyle()
                        }
                    }
                    mobileSignatureItem(mobileSignatureStatus: store.state.mobileSignatureStatus)
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
        .sheet(item: $store.state.presentedUpsell) { upsellScreenModel in
            UpsellScreen(model: upsellScreenModel)
        }
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

    @ViewBuilder
    private func mobileSignatureItem(mobileSignatureStatus: MobileSignatureStatus) -> some View {
        let needsPaidVersion = mobileSignatureStatus == .needsPaidVersion

        FormBigButton(
            title: L10n.Settings.MobileSignature.title,
            accessoryType: needsPaidVersion ? .upsell : .symbol(.chevronRight),
            value: mobileSignatureStatus.isEnabled ? CommonL10n.on.string : CommonL10n.off.string,
            action: {
                if needsPaidVersion {
                    Task {
                        do {
                            try await store.presentUpsellScreen(presenter: upsellCoordinator)
                        } catch {
                            toastStateStore.present(toast: .error(message: error.localizedDescription))
                        }
                    }
                } else {
                    router.go(to: .mobileSignature)
                }
            }
        )
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
