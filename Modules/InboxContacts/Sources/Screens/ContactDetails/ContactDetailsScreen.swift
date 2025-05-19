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

import InboxCoreUI
import InboxDesignSystem
import proton_app_uniffi
import SwiftUI

struct ContactDetailsScreen: View {
    let contact: ContactItem
    let provider: ContactDetailsProvider
    @State var state: ContactDetails

    /// `state` parameter is exposed only for testing purposes to be able to rely on data source in synchronous manner.
    init(
        contact: ContactItem,
        provider: ContactDetailsProvider,
        state: ContactDetails? = nil
    ) {
        self.contact = contact
        self.provider = provider
        _state = .init(initialValue: state ?? .details(with: contact))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.large) {
                avatarView
                contactDetails
                actionButtons
                fields
            }
            .padding(.horizontal, DS.Spacing.large)
        }
        .background(DS.Color.Background.secondary)
        .onLoad { loadDetails(for: contact) }
    }

    // MARK: - Private

    private var avatarView: some View {
        ZStack {
            Rectangle()
                .fill(Color(hex: state.avatarInformation.color))
                .square(size: 100)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.giant))
            Text(state.avatarInformation.text)
                .font(.title)
                .fontWeight(.regular)
                .foregroundStyle(DS.Color.Text.inverted)
        }
    }

    private var contactDetails: some View {
        VStack(spacing: DS.Spacing.compact) {
            Text(state.displayName)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(DS.Color.Text.norm)
            Text(state.primaryEmail)
                .font(.subheadline)
                .fontWeight(.regular)
                .foregroundStyle(DS.Color.Text.weak)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: DS.Spacing.standard) {
            ContactDetailsActionButton(
                image: DS.Icon.icPenSquare,
                title: "Message",
                disabled: false,
                action: {
                    // FIXME: Implement new message action
                }
            )
            ContactDetailsActionButton(
                image: DS.Icon.icPhone,
                title: "Call",
                disabled: state.primaryPhone == nil,
                action: {
                    // FIXME: Implement call action
                }
            )
            ContactDetailsActionButton(
                image: DS.Icon.icArrowUpFromSquare,
                title: "Share",
                disabled: false,
                action: {
                    // FIXME: Implement share action
                }
            )
        }
    }

    private var fields: some View {
        ForEach(state.groupItems, id: \.self) { items in
            FormList(collection: items, separator: .invertedNoPadding) { item in
                FormBigButton(
                    title: item.label.stringResource,
                    icon: .none,
                    value: item.value,
                    action: {
                        // FIXME: Implement action for specific item
                    },
                    isInteractive: item.isInteractive
                )
            }
        }
    }

    private func loadDetails(for contact: ContactItem) {
        Task {
            let details = await provider.contactDetails(for: contact)
            state = details
        }
    }
}

#Preview {
    ContactDetailsScreen(
        contact: .init(
            id: .random(),
            name: .empty,
            avatarInformation: .init(text: "BA", color: "#3357FF"),
            emails: []
        ),
        provider: .previewInstance()
    )
}

private extension ContactDetails {

    static func details(with contact: ContactItem) -> Self {
        .init(
            id: contact.id,
            avatarInformation: contact.avatarInformation,
            displayName: contact.name,
            primaryEmail: contact.emails.first?.email ?? .empty,
            primaryPhone: .none,
            groupItems: []
        )
    }

}
