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
import SwiftUI

enum AppSettingsAction {
    case notificationButtonTapped
    case onAppear
}

final class AppSettingsStateStore: StateStore, Sendable {
    @Published var state: AppSettingsState
    private let notificationCenter: UserNotificationCenter
    private let urlOpener: URLOpener

    @MainActor
    init(
        state: AppSettingsState,
        notificationCenter: UserNotificationCenter = UNUserNotificationCenter.current(),
        urlOpener: URLOpener = UIApplication.shared
    ) {
        self.state = state
        self.notificationCenter = notificationCenter
        self.urlOpener = urlOpener
    }

    @MainActor
    func handle(action: AppSettingsAction) async {
        switch action {
        case .notificationButtonTapped:
            await handleNotificationsFlow()
        case .onAppear:
            await refreshDeviceSettings()
        }
    }

    // MARK: - Private

    @MainActor
    private func refreshDeviceSettings() async {
        let areNotificationsEnabled = await areNotificationsEnabled()
        state = state.copy(\.areNotificationsEnabled, to: areNotificationsEnabled)
    }

    private func requestNotificationAuthorization() async {
        do {
            _ = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            AppLogger.log(error: error, category: .notifications)
        }
    }

    @MainActor
    private func handleNotificationsFlow() async {
        if await notificationCenter.authorizationStatus() == .notDetermined {
            await requestNotificationAuthorization()
            await refreshDeviceSettings()
        } else {
            await urlOpener.open(.settings, options: [:])
        }
    }

    private func areNotificationsEnabled() async -> Bool {
        switch await notificationCenter.authorizationStatus() {
        case .authorized:
            true
        case .denied, .ephemeral, .notDetermined, .provisional:
            false
        @unknown default:
            fatalError()
        }
    }

}

extension URL {

    static var settings: URL {
        URL(string: UIApplication.openSettingsURLString)!
    }

}

struct AppSettingsScreen: View {
    @EnvironmentObject var toastStateStore: ToastStateStore
    @StateObject var store: AppSettingsStateStore

    init(state: AppSettingsState = .initial) {
        self._store = .init(wrappedValue: .init(state: state))
    }

    var body: some View {
        ZStack {
            DS.Color.BackgroundInverted.norm
                .ignoresSafeArea(edges: .all)

            ScrollView {
                VStack(spacing: DS.Spacing.extraLarge) {
                    FormSection(header: L10n.Settings.App.deviceSectionTitle) {
                        VStack(spacing: DS.Spacing.moderatelyLarge) {
                            FormBigButton(
                                title: L10n.Settings.App.notifications,
                                icon: DS.SFSymbols.arrowUpRightSquare,
                                value: store.state.areNotificationsEnabledHumanReadable,
                                action: { store.handle(action: .notificationButtonTapped) }
                            )
                            FormBigButton(
                                title: L10n.Settings.App.language,
                                icon: DS.SFSymbols.arrowUpRightSquare,
                                value: "English",
                                action: { comingSoon() }
                            )
                            FormBigButton(
                                title: L10n.Settings.App.appearance,
                                icon: DS.SFSymbols.chevronUpChevronDown,
                                value: "Dark mode",
                                action: { comingSoon() }
                            )
                            FormBigButton(
                                title: L10n.Settings.App.protection,
                                icon: DS.SFSymbols.chevronRight,
                                value: "PIN code",
                                action: { comingSoon() }
                            )
                            FormSwitchView(
                                title: L10n.Settings.App.combinedContacts,
                                additionalInfo: L10n.Settings.App.combinedContactsInfo,
                                isOn: comingSoonBinding
                            )
                        }
                    }
                    FormSection(header: L10n.Settings.App.mailExperience) {
                        VStack(spacing: DS.Spacing.moderatelyLarge) {
                            FormSwitchView(
                                title: L10n.Settings.App.swipeToNextEmail,
                                additionalInfo: L10n.Settings.App.swipeToNextEmailInfo,
                                isOn: comingSoonBinding
                            )
                        }
                    }
                    FormSection(header: L10n.Settings.App.advanced) {
                        VStack(spacing: DS.Spacing.moderatelyLarge) {
                            FormSwitchView(
                                title: L10n.Settings.App.alternativeRouting,
                                additionalInfo: L10n.Settings.App.alternativeRoutingInfo,
                                isOn: comingSoonBinding
                            )
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.large)
                .padding(.bottom, DS.Spacing.extraLarge)
            }
        }
        .navigationTitle(L10n.Settings.App.title.string)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            store.handle(action: .onAppear)
        }
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
        AppSettingsScreen(state: .init(areNotificationsEnabled: false))
    }
}
