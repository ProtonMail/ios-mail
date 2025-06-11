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
import proton_app_uniffi
import SwiftUI

struct ContactDetailsScreen: View {
    let contact: ContactItem
    private let initialState: ContactDetails?
    private let provider: ContactDetailsProvider
    @Environment(\.openURL) var urlOpener

    /// `state` parameter is exposed only for testing purposes to be able to rely on data source in synchronous manner.
    init(
        contact: ContactItem,
        provider: ContactDetailsProvider,
        state: ContactDetails? = nil
    ) {
        self.contact = contact
        self.initialState = state
        self.provider = provider
    }

    var body: some View {
        StoreView(
            store: ContactDetailsStateStore(
                state: initialState ?? .initial(with: contact),
                item: contact,
                provider: provider,
                urlOpener: urlOpener
            )
        ) { state, store in
            ScrollView {
                VStack(spacing: DS.Spacing.large) {
                    avatarView(state: state)
                    contactDetails(state: state)
                    actionButtons(state: state)
                    fields(state: state, store: store)
                }
                .padding(.horizontal, DS.Spacing.large)
            }
            .background(DS.Color.Background.secondary)
            .onLoad { store.handle(action: .onLoad) }
        }

    }

    // MARK: - Private

    private func avatarView(state: ContactDetailsStateStore.State) -> some View {
        ContactAvatarView(hexColor: state.avatarInformation.color) {
            Text(state.avatarInformation.text)
                .font(.title)
                .fontWeight(.regular)
                .foregroundStyle(DS.Color.Text.inverted)
        }
    }

    private func contactDetails(state: ContactDetailsStateStore.State) -> some View {
        ContactAvatarDetailsView(title: state.displayName, subtitle: state.primaryEmail)
    }

    private func actionButtons(
        state: ContactDetailsStateStore.State
    ) -> some View {
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

    private func fields(state: ContactDetailsStateStore.State, store: ContactDetailsStateStore) -> some View {
        ForEach(state.items, id: \.self) { item in
            field(for: item, store: store)
        }
    }

    @ViewBuilder
    private func field(for type: ContactField, store: ContactDetailsStateStore) -> some View {
        switch type {
        case .anniversary(let date):
            singleButton(
                item: ContactFormatter.Date.formatted(from: date, with: L10n.ContactDetails.Label.anniversary.string)
            )
        case .birthday(let date):
            singleButton(
                item: ContactFormatter.Date.formatted(from: date, with: L10n.ContactDetails.Label.birthday.string)
            )
        case .gender(let gender):
            singleButton(item: ContactFormatter.Gender.formatted(from: gender))
        case .addresses(let addresses):
            FormList(collection: addresses) { address in
                button(item: ContactFormatter.Address.formatted(from: address))
            }
        case .emails(let emails):
            FormList(collection: emails) { item in
                button(item: .init(label: item.name, value: item.email, isInteractive: true)) {
                    // FIXME: Implement copy action
                }
            }
        case .languages(let languages):
            nonInteractiveGroup(label: L10n.ContactDetails.Label.language.string, values: languages)
        case .members(let members):
            nonInteractiveGroup(label: L10n.ContactDetails.Label.member.string, values: members)
        case .notes(let notes):
            nonInteractiveGroup(label: L10n.ContactDetails.Label.note.string, values: notes)
        case .organizations(let organizations):
            nonInteractiveGroup(label: L10n.ContactDetails.Label.organization.string, values: organizations)
        case .telephones(let telephones):
            FormList(collection: telephones) { telephone in
                button(item: ContactFormatter.Telephone.formatted(from: telephone)) {
                    // FIXME: Implement call action
                }
            }
        case .roles(let roles):
            nonInteractiveGroup(label: L10n.ContactDetails.Label.role.string, values: roles)
        case .timeZones(let timeZones):
            nonInteractiveGroup(label: L10n.ContactDetails.Label.timeZone.string, values: timeZones)
        case .titles(let titles):
            nonInteractiveGroup(label: L10n.ContactDetails.Label.title.string, values: titles)
        case .urls(let urls):
            FormList(collection: urls) { item in
                button(item: ContactFormatter.URL.formatted(from: item)) {
                    store.handle(action: .openURL(urlString: item.url))
                }
            }
        case .logos, .photos:
            EmptyView()
        }
    }

    private func nonInteractiveGroup(label: String, values: [String]) -> some View {
        FormList(collection: values) { value in
            button(item: .init(label: label, value: value, isInteractive: false))
        }
    }

    private func button(item: ContactDetailsItem, action: @escaping () -> Void = {}) -> some View {
        LongPressFormBigButton(
            title: item.label.stringResource,
            value: item.value,
            hasAccentTextColor: item.isInteractive,
            onTap: action
        )
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
