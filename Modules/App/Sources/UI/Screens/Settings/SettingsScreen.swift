// Copyright (c) 2024 Proton Technologies AG
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

struct SettingsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appAppearanceStore: AppAppearanceStore
    @StateObject var router: Router<SettingsRoute>
    @State private var state: SettingsState
    private let provider: AccountDetailsProvider
    private let viewFactory: SettingsViewFactory

    init(state: SettingsState = .initial, mailUserSession: MailUserSession) {
        _state = .init(initialValue: state)
        _router = .init(wrappedValue: .init())
        self.provider = .init(mailUserSession: mailUserSession)
        self.viewFactory = .init(mailUserSession: mailUserSession)
    }

    var body: some View {
        NavigationStack(path: navigationPath) {
            ZStack {
                DS.Color.Background.secondary
                    .ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: .zero) {
                        accountSection()
                        preferencesSection()
                    }
                }
                .padding(.horizontal, DS.Spacing.large)
                .navigationTitle(L10n.Settings.title.string)
                .toolbarTitleDisplayMode(.large)
                .toolbarBackground(DS.Color.BackgroundInverted.norm, for: .navigationBar)
                .toolbar { doneToolbarItem() }
            }
            .navigationDestination(for: SettingsRoute.self) { route in
                viewFactory
                    .makeView(for: route)
                    .environmentObject(router)
                    .navigationBarBackButtonHidden()
                    .toolbar {
                        ToolbarItemFactory.back {
                            router.goBack()
                        }
                    }
            }
        }
        .task {
            async let accountDetails = provider.accountDetails()
            async let userSettings = provider.userSettings()

            if let details = await accountDetails {
                state = state.copy(\.accountSettings, to: details.settings)
            }

            if let isEasyDeviceMigrationDisabled = await userSettings?.flags.edmOptOut {
                state = state
                    .copy(\.showSignInToAnotherDevice, to: !isEasyDeviceMigrationDisabled)
            }
        }
        .preferredColorScheme(appAppearanceStore.colorScheme)
    }

    // MARK: - Private

    private func doneToolbarItem() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: { dismiss.callAsFunction() }) {
                Text(CommonL10n.done)
                    .foregroundStyle(DS.Color.InteractionBrand.norm)
            }
        }
    }

    private var navigationPath: Binding<[SettingsRoute]> {
        .init(
            get: { router.stack },
            set: { router.stack = $0 }
        )
    }

    private func preferencesSection() -> some View {
        FormSection(header: L10n.Settings.preferences) {
            FormList(collection: state.preferences, separator: .normLeftPadding) { preference in
                settingsRow(
                    icon: preference.displayData.icon,
                    title: preference.displayData.title,
                    action: {
                        switch preference {
                        case .email, .filters, .foldersAndLabels, .privacyAndSecurity:
                            if let page = preference.webPage {
                                router.go(to: .webView(page))
                            }
                        case .app:
                            router.go(to: .appSettings)
                        }
                    }
                )
            }
        }
    }

    @ViewBuilder
    private func accountSection() -> some View {
        VStack(alignment: .center, spacing: DS.Spacing.compact) {
            accountDetails()
            if state.showSignInToAnotherDevice {
                signInToAnotherDevice()
            }
        }
        .padding(.bottom, DS.Spacing.large)
        .padding(.top, DS.Spacing.large)
    }

    @ViewBuilder
    private func signInToAnotherDevice() -> some View {
        Button(action: {
            Task { @MainActor in
                router.go(to: .scanQRCode)
            }
        }) {
            HStack(spacing: DS.Spacing.large) {
                Image(DS.Icon.icQrCode)
                    .resizable()
                    .square(size: 20)
                    .foregroundStyle(DS.Color.Icon.norm)
                    .padding(.horizontal, 14)

                Text(L10n.Settings.signInOnAnotherDevice)
                    .foregroundStyle(DS.Color.Text.norm)

                Spacer()

                Image(symbol: .chevronRight)
                    .font(.system(size: 17))
                    .foregroundStyle(DS.Color.Text.hint)
            }
            .padding(.all, DS.Spacing.large)
            .contentShape(Rectangle())
        }
        .buttonStyle(DefaultPressedButtonStyle())
        .background(DS.Color.BackgroundInverted.secondary)
        .roundedRectangleStyle()
    }

    @ViewBuilder
    private func accountDetails() -> some View {
        if let details = state.accountSettings {
            Button(action: {
                router.go(to: .webView(.accountSettings))
            }) {
                HStack(spacing: DS.Spacing.large) {
                    ZStack {
                        Color(details.avatarInfo.color)
                        Text(details.avatarInfo.initials)
                            .opacity(0.8)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(DS.Color.Global.white)
                    }
                    .square(size: 48)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large))

                    VStack(alignment: .leading, spacing: DS.Spacing.compact) {
                        Text(details.name)
                            .lineLimit(1)
                            .foregroundStyle(DS.Color.Text.norm)
                            .fontWeight(.semibold)
                        Text(verbatim: details.email)
                            .foregroundStyle(DS.Color.Text.weak)
                            .font(.subheadline)
                    }

                    Spacer()

                    Image(symbol: .chevronRight)
                        .font(.system(size: 17))
                        .foregroundStyle(DS.Color.Text.hint)
                }
                .padding(.all, DS.Spacing.large)
                .contentShape(Rectangle())
            }
            .buttonStyle(DefaultPressedButtonStyle())
            .background(DS.Color.BackgroundInverted.secondary)
            .roundedRectangleStyle()
        }
    }

    private func settingsRow(
        icon: ImageResource,
        title: LocalizedStringResource,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: { action() }) {
            VStack(spacing: .zero) {
                HStack(spacing: DS.Spacing.large) {
                    Image(icon)
                        .resizable()
                        .square(size: 20)
                        .foregroundStyle(DS.Color.Icon.norm)
                    Text(title)
                        .foregroundStyle(DS.Color.Text.norm)
                    Spacer(minLength: DS.Spacing.medium)
                    Image(symbol: .chevronRight)
                        .font(.system(size: 17))
                        .foregroundStyle(DS.Color.Text.hint)
                }
                .padding(DS.Spacing.large)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(DefaultPressedButtonStyle())
    }

}

private extension SettingsPreference {

    var webPage: ProtonAuthenticatedWebPage? {
        switch self {
        case .email:
            return .emailSettings
        case .foldersAndLabels:
            return .createFolderOrLabel
        case .filters:
            return .spamFiltersSettings
        case .privacyAndSecurity:
            return .privacySecuritySettings
        case .app:
            return nil
        }
    }

}

#Preview {
    NavigationStack {
        SettingsScreen(mailUserSession: MailUserSession(noPointer: .init()))
    }
}
