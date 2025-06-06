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
        _state = .init(initialValue: state ?? .initial(with: contact))
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
        ContactAvatarView(hexColor: state.avatarInformation.color) {
            Text(state.avatarInformation.text)
                .font(.title)
                .fontWeight(.regular)
                .foregroundStyle(DS.Color.Text.inverted)
        }
    }

    private var contactDetails: some View {
        ContactAvatarDetailsView(title: state.displayName, subtitle: state.primaryEmail)
    }

    private var actionButtons: some View {
        HStack(spacing: DS.Spacing.standard) {
            ContactDetailsActionButton(
                image: DS.Icon.icPenSquare,
                title: L10n.ContactDetails.newMessage,
                disabled: false,
                action: {
                    // FIXME: Implement new message action
                }
            )
            ContactDetailsActionButton(
                image: DS.Icon.icPhone,
                title: L10n.ContactDetails.call,
                disabled: state.primaryPhone == nil,
                action: {
                    // FIXME: Implement call action
                }
            )
            ContactDetailsActionButton(
                image: DS.Icon.icArrowUpFromSquare,
                title: L10n.ContactDetails.share,
                disabled: false,
                action: {
                    // FIXME: Implement share action
                }
            )
        }
    }

    private var fields: some View {
        ForEach(state.items, id: \.self) { item in
            field(for: item)
        }
    }

    @ViewBuilder
    private func field(for type: ContactField) -> some View {
        switch type {
        case .anniversary(let date):
            dateField(label: "Anniversary", from: date)
        case .birthday(let date):
            dateField(label: "Birthday", from: date)
        case .gender(let gender):
            singleButton(item: ContactFormatter.Gender.formatted(from: gender))
        case .addresses(let addresses):
            FormList(collection: addresses) { address in
                button(item: ContactFormatter.Address.formatted(from: address)) {
                    // FIXME: Implement action for opening apple maps / google maps
                }
            }
        case .emails(let emails):
            FormList(collection: emails) { item in
                button(item: .init(label: item.name, value: item.email, isInteractive: true)) {
                    // FIXME: Implement copy action
                }
            }
        case .languages(let languages):
            nonInteractiveGroup(label: "Language", values: languages)
        case .logos:
            EmptyView()
        case .members(let members):
            nonInteractiveGroup(label: "Member", values: members)
        case .notes(let notes):
            nonInteractiveGroup(label: "Note", values: notes)
        case .organizations(let organizations):
            nonInteractiveGroup(label: "Organization", values: organizations)
        case .telephones(let telephones):
            FormList(collection: telephones) { telephone in
                button(item: ContactFormatter.Telephone.formatted(from: telephone)) {
                    // FIXME: Implement call action
                }
            }
        case .photos:
            EmptyView()
        case .roles(let roles):
            nonInteractiveGroup(label: "Role", values: roles)
        case .timeZones(let timeZones):
            nonInteractiveGroup(label: "Time zone", values: timeZones)
        case .titles(let titles):
            nonInteractiveGroup(label: "Title", values: titles)
        case .urls(let urls):
            FormList(collection: urls) { item in
                button(item: ContactFormatter.URL.formatted(from: item)) {
                    // FIXME: Implement copy / open url action
                }
            }
        }
    }

    private func loadDetails(for contact: ContactItem) {
        Task {
            state = await provider.contactDetails(for: contact)
        }
    }

    private func nonInteractiveGroup(label: String, values: [String]) -> some View {
        FormList(collection: values) { value in
            button(item: .init(label: label, value: value, isInteractive: false))
        }
    }

    private func button(item: ContactDetailsItem, action: @escaping () -> Void = {}) -> some View {
        FormBigButton(
            title: item.label.stringResource,
            symbol: .none,
            value: item.value,
            action: action,
            hasAccentTextColor: item.isInteractive
        )
        .disabled(!item.isInteractive)
    }

    private func dateField(label: String, from date: ContactDate) -> some View {
        let formattedDate: String
        switch date {
        case .string(let string):
            formattedDate = string
        case .date:
            formattedDate = "N/A"
        }

        return singleButton(item: .init(label: label, value: formattedDate, isInteractive: false))
    }

    private func singleButton(item: ContactDetailsItem, action: @escaping () -> Void = {}) -> some View {
        button(item: item, action: action)
            .background(DS.Color.BackgroundInverted.secondary)
            .roundedRectangleStyle()
    }
}

private extension ContactDetails {

    static func initial(with contact: ContactItem) -> Self {
        .init(contact: contact, details: .none)
    }

}

private extension FormList {

    init(collection: Collection, elementContent: @escaping (Collection.Element) -> ElementContent) {
        self.init(collection: collection, separator: .invertedNoPadding, elementContent: elementContent)
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
