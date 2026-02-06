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

import AccountLogin
import AccountPassword
import InboxCore
import InboxCoreUI
import InboxDesignSystem
import InboxIAP
import ProtonUIFoundations
import SwiftUI
import proton_app_uniffi

struct SettingsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appAppearanceStore: AppAppearanceStore
    @StateObject var router: Router<SettingsRoute>
    @State private var state: SettingsState
    private let provider: AccountDetailsProvider
    private let viewFactory: SettingsViewFactory

    private enum Constants {
        static let defaultFont: Font = .system(size: 17)
    }

    init(
        state: SettingsState = .initial,
        mailUserSession: MailUserSession,
        accountAuthCoordinator: AccountAuthCoordinator,
        upsellCoordinator: UpsellCoordinator
    ) {
        _state = .init(initialValue: state)
        _router = .init(wrappedValue: .init())
        self.provider = .init(mailUserSession: mailUserSession)
        self.viewFactory = .init(
            mailUserSession: mailUserSession,
            accountAuthCoordinator: accountAuthCoordinator,
            upsellCoordinator: upsellCoordinator
        )
    }

    var body: some View {
        NavigationStack(path: navigationPath) {
            ZStack {
                DS.Color.Background.secondary
                    .ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: .zero) {
                        headerSection()
                        accountSection()
                        storageSection()
                        preferencesSection()
                    }
                    .padding(.horizontal, DS.Spacing.large)
                }
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
            async let hasMailboxPassword = provider.mailUserSession.hasMailboxPassword()
            async let user = provider.user()

            if let details = await accountDetails {
                state = state.copy(\.accountInfo, to: details.settings)
            }

            if let settings = await userSettings {
                state = state.copy(\.userSettings, to: settings)
            }

            state = state.copy(\.hasMailboxPassword, to: await hasMailboxPassword)

            if let userInfo = await user {
                let storageInfo = StorageInfo(usedSpace: userInfo.usedSpace, maxSpace: userInfo.maxSpace)
                state = state.copy(\.storageInfo, to: storageInfo)
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

    @ViewBuilder
    private func headerSection() -> some View {
        VStack(alignment: .center, spacing: DS.Spacing.compact) {
            accountDetails()
        }
        .padding(.top, DS.Spacing.large)
    }

    private func accountSection() -> some View {
        FormSection {
            FormList(collection: state.accountSettings, style: .separator(.normLeftPadding)) { preference in
                settingsRow(
                    icon: preference.displayData.icon,
                    title: preference.displayData.title,
                    action: {
                        switch preference {
                        case .qrLogin:
                            router.go(to: .scanQRCode)
                        case .changePassword:
                            router.go(to: passwordChangeRoute(for: .singlePassword(provider.mailUserSession)))
                        case .changeLoginPassword:
                            router.go(to: passwordChangeRoute(for: .loginPassword(provider.mailUserSession)))
                        case .changeMailboxPassword:
                            router.go(to: passwordChangeRoute(for: .mailboxPassword(provider.mailUserSession)))
                        case .securityKeys:
                            if let userSettings = state.userSettings {
                                router.go(to: .securityKeys(userSettings))
                            }
                        }
                    }
                )
            }
        }
        .padding(.bottom, DS.Spacing.large)
    }

    private func passwordChangeRoute(for mode: PasswordChange.Mode) -> SettingsRoute {
        .changePassword(
            .init(mode: mode) { [weak router] state in
                if let state {
                    router?.go(to: .changePassword(state))
                } else {
                    router?.goBack(while: \.isChangePassword)
                }
            }
        )
    }

    @ViewBuilder
    private func storageSection() -> some View {
        if let storage = state.storageInfo {
            Button(action: { router.go(to: .subscription) }) {
                VStack(spacing: .zero) {
                    HStack(spacing: DS.Spacing.mediumLight) {
                        ZStack {
                            Color(storage.isNearingOutOfStorage ? DS.Color.Notification.error : DS.Color.Notification.success)
                                .opacity(0.1)
                            Image(Theme.icon.storage)
                                .resizable()
                                .square(size: 20)
                                .foregroundStyle(storage.isNearingOutOfStorage ? DS.Color.Notification.error : DS.Color.Notification.success)
                        }
                        .square(size: 32)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))

                        Text(storage.formattedStorage)
                            .foregroundStyle(storage.isNearingOutOfStorage ? DS.Color.Notification.error : DS.Color.Text.norm)
                        Spacer(minLength: DS.Spacing.medium)
                        Image(symbol: .chevronRight)
                            .font(Constants.defaultFont)
                            .foregroundStyle(DS.Color.Text.hint)
                    }
                    .padding(.vertical, DS.Spacing.medium)
                    .padding(.trailing, DS.Spacing.large)
                    .padding(.leading, DS.Spacing.mediumLight)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(DefaultPressedButtonStyle())
            .background(DS.Color.BackgroundInverted.secondary)
            .roundedRectangleStyle()
            .padding(.bottom, DS.Spacing.large)
        }
    }

    private func preferencesSection() -> some View {
        FormSection(header: L10n.Settings.preferences) {
            FormList(collection: state.preferences, style: .separator(.normLeftPadding)) { preference in
                settingsRow(
                    icon: preference.displayData.icon,
                    title: preference.displayData.title,
                    action: {
                        switch preference {
                        case .email, .filters, .foldersAndLabels, .privacyAndSecurity:
                            if let page = preference.webPage {
                                router.go(to: .webView(page))
                            }
                        case .signatures:
                            router.go(to: .signatures)
                        case .app:
                            router.go(to: .appSettings)
                        }
                    }
                )
            }
        }
    }

    @ViewBuilder
    private func accountDetails() -> some View {
        if let details = state.accountInfo {
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
                        .font(Constants.defaultFont)
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
                        .font(Constants.defaultFont)
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
        case .signatures, .app:
            return nil
        }
    }
}

#if DEBUG
    #Preview {
        NavigationStack {
            SettingsScreen(
                mailUserSession: MailUserSession(noPointer: .init()),
                accountAuthCoordinator: .mock(),
                upsellCoordinator: .init(
                    mailUserSession: .dummy,
                    userAttributionService: .init(
                        userSettingsProvider: { .mock() },
                        userDefaults: UserDefaults()
                    ),
                    configuration: .mail
                )
            )
        }
    }
#endif
