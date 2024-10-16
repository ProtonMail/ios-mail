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
import ProtonCoreUI
import SwiftUI

public struct ContactsScreen: View {
    @State private var groupedContacts: [GroupedContacts] = []

    public init() {}

    var didCallTask: ((Self) -> Void)?

    public var body: some View {
        NavigationStack {
            ZStack {
                DS.Color.Background.secondary
                    .ignoresSafeArea()
                List {
                    sections(for: groupedContacts)
                }
                .styledGroupedContacts()
            }
            .navigationTitle("Contacts")
        }
        .onLoad { groupedContacts = groupedContactsDataSource.allContacts() }
    }

    // MARK: - Private

    private let groupedContactsDataSource = GroupedContactsDataSource()

    private func sections(for groupedContacts: [GroupedContacts]) -> some View {
        ForEach(groupedContacts, id: \.self) { groupedContacts in
            Section(header: EmptyView()) {
                ForEach(groupedContacts.contacts, id: \.self) { contactType in
                    row(for: contactType)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .alignmentGuide(.listRowSeparatorLeading) { _ in -DS.Spacing.large }
                .listRowBackground(DS.Color.Background.norm)
                .listRowInsets(.init(vertical: DS.Spacing.medium, horizontal: DS.Spacing.large))
                .listRowSeparatorTint(DS.Color.Border.norm)
            }
        }
    }

    @ViewBuilder
    private func row(for contactType: ContactType) -> some View {
        switch contactType {
        case .contact(let contactItem):
            contactRow(for: contactItem)
        case .group(let groupItem):
            groupRow(for: groupItem)
        }
    }

    private func contactRow(for item: ContactItem) -> some View {
        HStack(spacing: DS.Spacing.large) {
            Text(item.avatarInformation.text)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(DS.Color.Text.inverted)
                .square(size: 40)
                .background(Color(hex: item.avatarInformation.color), in: Circle())
            texts(title: item.name, subtitle: item.emails.first?.email)
        }
    }

    private func groupRow(for item: ContactGroupItem) -> some View {
        HStack(spacing: DS.Spacing.large) {
            Image(DS.Icon.icUsers)
                .foregroundColor(DS.Color.Text.inverted)
                .square(size: 20)
                .padding(10)
                .background(Color(hex: item.avatarColor), in: Circle())
            texts(title: item.name, subtitle: "\(item.emails.count) members")
        }
    }

    private func texts(title: String, subtitle: String?) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.small) {
            Text(title)
                .font(.body)
                .fontWeight(.regular)
                .foregroundStyle(DS.Color.Text.weak)
                .lineLimit(1)
            if let subtitle = subtitle {
                Text(subtitle)
                    .fontBody3()
                    .fontWeight(.regular)
                    .foregroundStyle(DS.Color.Text.hint)
                    .lineLimit(1)
            }
        }
    }
}

private extension List {

    func styledGroupedContacts() -> some View {
        contentMargins(.horizontal, DS.Spacing.large, for: .scrollContent)
            .listSectionSpacing(DS.Spacing.large)
            .listStyle(InsetGroupedListStyle())
    }

}

#Preview {
    ContactsScreen()
}
