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

import InboxCoreUI
import InboxDesignSystem
import proton_app_uniffi
import SwiftUI

struct SettingsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var toastStateStore: ToastStateStore
    @State private var state: SettingsState
    private let provider: AccountDetailsProvider

    init(state: SettingsState = .initial, mailUserSession: MailUserSession) {
        _state = .init(initialValue: state)
        self.provider = .init(mailUserSession: mailUserSession)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Color.Background.secondary
                    .ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: .zero) {
                        accountDetails()
                        preferencesSection()
                    }
                }
                .padding(.horizontal, DS.Spacing.large)
                .navigationTitle(L10n.Settings.title.string)
                .toolbarTitleDisplayMode(.large)
                .toolbarBackground(DS.Color.BackgroundInverted.norm, for: .navigationBar)
                .toolbar { doneToolbarItem() }
            }
            .navigationDestination(item: presentedWebPage) { webPage in
                ProtonAuthenticatedWebView(webViewPage: webPage)
                    .background(DS.Color.BackgroundInverted.norm)
                    .edgesIgnoringSafeArea(.bottom)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItemFactory.back {
                            popWebPage()
                        }
                        doneToolbarItem()
                    }
                    .navigationTitle(webPage.title.string)
                    .navigationBarBackButtonHidden(true)
            }
        }
        .task {
            if let details = await provider.accountDetails() {
                state = state.copy(with: details)
            }
        }
    }

    // MARK: - Private

    private var presentedWebPage: Binding<ProtonAuthenticatedWebPage?> {
        Binding(
            get: { state.presentedWebPage },
            set: { newValue in state = state.copy(presentedWebPage: newValue) }
        )
    }

    private func doneToolbarItem() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: { dismiss.callAsFunction() }) {
                Text(L10n.Common.done)
                    .foregroundStyle(DS.Color.InteractionBrand.norm)
            }
        }
    }

    private func preferencesSection() -> some View {
        VStack(spacing: .zero) {
            Text(L10n.Settings.preferences)
                .font(.callout)
                .fontWeight(.semibold)
                .padding(.bottom, DS.Spacing.mediumLight)
                .padding(.leading, DS.Spacing.large)

            LazyVStack(spacing: .zero) {
                ForEachLast(collection: state.preferences) { preference, isLast in
                    settingsRow(
                        icon: preference.displayData.icon,
                        title: preference.displayData.title,
                        isLast: isLast
                    ) {
                        present(page: preference.webPage)
                    }
                }
            }
            .background(DS.Color.BackgroundInverted.secondary)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.extraLarge))
        }
    }

    @ViewBuilder
    private func accountDetails() -> some View {
        if let details = state.accountSettings {
            Button(action: {
                present(page: .accountSettings)
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

                    Image(systemName: DS.SFSymbols.chevronRight)
                        .font(.system(size: 17))
                        .foregroundStyle(DS.Color.Text.hint)
                }
                .padding(.all, DS.Spacing.large)
                .contentShape(Rectangle())
            }
            .buttonStyle(SettingsButtonStyle())
            .background(DS.Color.BackgroundInverted.secondary) // This can be reused
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.extraLarge)) // This can be reused
            .padding(.bottom, DS.Spacing.huge)
            .padding(.top, DS.Spacing.large)
        }
    }

    private func settingsRow(
        icon: ImageResource,
        title: LocalizedStringResource,
        isLast: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: { action() }) {
            VStack(spacing: .zero) {
                HStack(spacing: DS.Spacing.large) {
                    Image(icon)
                        .resizable()
                        .square(size: 24)
                        .foregroundStyle(DS.Color.Icon.norm)
                    Text(title)
                        .foregroundStyle(DS.Color.Text.norm)
                    Spacer(minLength: DS.Spacing.medium)
                    Image(systemName: DS.SFSymbols.chevronRight)
                        .font(.system(size: 17))
                        .foregroundStyle(DS.Color.Text.hint)
                }
                .padding(DS.Spacing.large)

                if !isLast {
                    DS.Color.Border.norm
                        .frame(height: 1)
                        .padding(.leading, 56)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(SettingsButtonStyle())
    }

    private func present(page: ProtonAuthenticatedWebPage?) {
        if let page {
            state = state.copy(presentedWebPage: page)
        } else {
            toastStateStore.present(toast: .comingSoon)
        }
    }

    private func popWebPage() {
        state = state.copy(presentedWebPage: nil)
    }

}

private extension ProtonAuthenticatedWebPage {

    var title: LocalizedStringResource {
        switch self {
        case .accountSettings:
            L10n.Settings.account
        case .emailSettings:
            L10n.Settings.email
        case .spamFiltersSettings:
            L10n.Settings.filters
        case .privacySecuritySettings:
            L10n.Settings.privacyAndSecurity
        case .createFolderOrLabel:
            L10n.Settings.foldersAndLabels
        }
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

private struct SettingsButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .background(configuration.isPressed ? DS.Color.InteractionWeak.pressed : .clear)
    }

}

#Preview {
    NavigationStack {
        SettingsScreen(mailUserSession: MailUserSession(noPointer: .init()))
    }
}
