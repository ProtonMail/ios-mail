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
import SwiftUIIntrospect

struct SettingsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var toastStateStore: ToastStateStore
    @State private var state: [SettingsItem]
    @State private var webViewPage: ProtonAuthenticatedWebPage?

    init() {
        _state = .init(initialValue: .stale)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Color.Background.secondary
                    .ignoresSafeArea()
                ScrollView {
                    section(items: state, header: "Preferences")
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, DS.Spacing.large)
                        .padding(.top, DS.Spacing.medium)
                }
                .navigationTitle("Settings")
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
                    .navigationBarBackButtonHidden(true)
            }
        }
    }

    // MARK: - Private

    private func section(items: [SettingsItem], header: String) -> some View {
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
    }

    private func buttonContent(item: SettingsItem) -> some View {
        VStack(spacing: .zero) {
            HStack(spacing: .zero) {
                Image(item.icon)
                    .square(size: 40)
                    .foregroundStyle(DS.Color.Brand.norm)
                    .background(DS.Color.Brand.minus30)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large))
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

    private func doneToolbarItem() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: { dismiss.callAsFunction() }) {
                Text("Done")
                    .foregroundStyle(DS.Color.Interaction.norm)
            }
        }
    }

    private func selected(item: SettingsItem) {
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

private extension Array where Element == SettingsItem {

    static var stale: [Element] {
        [.email, .foldersAndLabels, .filters, .privacyAndSecurity, .app]
    }

}

private extension SettingsItem {

    var webViewPage: ProtonAuthenticatedWebPage? {
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
