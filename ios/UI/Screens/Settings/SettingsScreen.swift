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

import DesignSystem
import SwiftUI

struct SettingsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var toastStateStore: ToastStateStore
    @State private var state: SettingsState
    @State private var webViewPage: ProtonAuthenticatedWebPage?

    init() {
        _state = .init(initialValue: .initial)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Color.Background.secondary
                    .ignoresSafeArea()
                ScrollView {
                    section(items: [.account(state.accountSettings)], header: L10n.Settings.account)
                    section(
                        items: state.preferences.map(SettingsItemType.preference),
                        header: L10n.Settings.preferences
                    )
                }
                .navigationTitle(L10n.Settings.title.string)
                .toolbarTitleDisplayMode(.large)
                .toolbarBackground(DS.Color.Background.secondary, for: .navigationBar)
                .toolbar {
                    doneToolbarItem()
                }
            }
            .navigationDestination(item: $webViewPage) { webViewPage in
                ProtonAuthenticatedWebView(webViewPage: webViewPage)
                    .background(DS.Color.Background.norm)
                    .edgesIgnoringSafeArea(.bottom)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(action: { self.webViewPage = nil }) {
                                Image(DS.Icon.icChevronTinyLeft)
                                    .foregroundStyle(DS.Color.Icon.weak)
                            }
                        }
                        doneToolbarItem()
                    }
                    .navigationTitle(webViewPage.title.string)
                    .navigationBarBackButtonHidden(true)
            }
        }
    }

    // MARK: - Private

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
                        Divider()
                            .frame(height: 1)
                            .background(DS.Color.Background.norm)
                    }
                }
            }
            .background(DS.Color.Background.norm)
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
                    Text(item.title)
                        .foregroundStyle(DS.Color.Text.weak)
                    Text(item.subtitle)
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
                Color(accountSettings.initialsBackground)
                Text(accountSettings.initials)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(DS.Color.Global.white)
            }
            .square(size: 40)
            .clipShape(Circle())
        case .preference(let settingsPreference):
            Image(settingsPreference.icon)
                .resizable()
                .square(size: 24)
                .foregroundStyle(DS.Color.Icon.norm)
                .square(size: 40)
        }
    }

    private func doneToolbarItem() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: { dismiss.callAsFunction() }) {
                Text(L10n.Common.done)
                    .foregroundStyle(DS.Color.Interaction.norm)
            }
        }
    }

    private func selected(item: SettingsItemType) {
        if let webViewPage = item.webViewPage {
            self.webViewPage = webViewPage
        } else {
            toastStateStore.present(toast: .comingSoon)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsScreen()
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
