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
                DS.Color.BackgroundInverted.norm
                    .ignoresSafeArea()
                ScrollView {
                    if let accountSettings = state.accountSettings {
                        section(items: [.account(accountSettings)], header: L10n.Settings.account)
                    }
                    section(
                        items: state.preferences.map(SettingsItemType.preference),
                        header: L10n.Settings.preferences
                    )
                }
                .navigationTitle(L10n.Settings.title.string)
                .toolbarTitleDisplayMode(.large)
                .toolbarBackground(DS.Color.BackgroundInverted.norm, for: .navigationBar)
                .toolbar {
                    doneToolbarItem()
                }
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

    private func section(items: [SettingsItemType], header: LocalizedStringResource) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.medium) {
            Text(header)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(DS.Color.Text.hint)

            VStack(spacing: .zero) {
                ForEach(items, id: \.self) { item in
                    Button(action: { selected(item: item) }) {
                        buttonContent(item: item)
                    }
                    if items.last != item {
                        DS.Color.BackgroundInverted.border
                            .frame(height: 1)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .listRowSeparator(.hidden)
            .background(DS.Color.BackgroundInverted.secondary)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.extraLarge))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, DS.Spacing.large)
        .padding(.top, DS.Spacing.medium)
    }

    private func buttonContent(item: SettingsItemType) -> some View {
        VStack(spacing: .zero) {
            HStack(spacing: .zero) {
                image(for: item)
                    .padding(.trailing, DS.Spacing.large)
                VStack(alignment: .leading, spacing: DS.Spacing.small) {
                    Text(item.displayData.title)
                        .foregroundStyle(DS.Color.Text.norm)
                    Text(item.displayData.subtitle)
                        .foregroundStyle(DS.Color.Text.hint)
                        .font(.subheadline)
                }
                Spacer()
                Image(DS.Icon.icChevronTinyRight)
                    .foregroundStyle(DS.Color.Icon.hint)

            }.padding(DS.Spacing.large)
        }
    }

    @ViewBuilder
    private func image(for item: SettingsItemType) -> some View {
        switch item {
        case .account(let accountSettings):
            ZStack {
                Color(accountSettings.avatarInfo.color)
                Text(accountSettings.avatarInfo.initials)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(DS.Color.Global.white)
            }
            .square(size: 40)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large))
        case .preference(let settingsPreference):
            Image(settingsPreference.displayData.icon)
                .resizable()
                .square(size: 24)
                .foregroundStyle(DS.Color.Icon.norm)
                .padding(DS.Spacing.standard)
        }
    }

    private func doneToolbarItem() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: { dismiss.callAsFunction() }) {
                Text(L10n.Common.done)
                    .foregroundStyle(DS.Color.InteractionBrand.norm)
            }
        }
    }

    private func selected(item: SettingsItemType) {
        if let webPage = item.displayData.webPage {
            state = state.copy(presentedWebPage: webPage)
        } else {
            toastStateStore.present(toast: .comingSoon)
        }
    }

    private func popWebPage() {
        state = state.copy(presentedWebPage: nil)
    }

}

#Preview {
    NavigationStack {
        SettingsScreen(mailUserSession: MailUserSession(noPointer: .init()))
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
