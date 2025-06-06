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

    @ViewBuilder
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
            singleButton(item: .init(label: "Gender", value: gender.humanReadable, isInteractive: false))
        case .addresses(let addresses):
            FormList(collection: addresses, separator: .invertedNoPadding) { address in
                addressField(from: address) {
                    // FIXME: Implement action for opening apple maps / google maps
                }
            }
        case .emails(let emails):
            FormList(collection: emails, separator: .invertedNoPadding) { item in
                button(item: .init(label: item.name, value: item.email, isInteractive: true)) {
                    // FIXME: Implement copy action
                }
            }
        case .languages(let languages):
            FormList(collection: languages, separator: .invertedNoPadding) { language in
                button(item: .init(label: "Language", value: language, isInteractive: false))
            }
        case .logos:
            EmptyView()
        case .members(let members):
            FormList(collection: members, separator: .invertedNoPadding) { member in
                button(item: .init(label: "Member", value: member, isInteractive: false))
            }
        case .notes(let notes):
            FormList(collection: notes, separator: .invertedNoPadding) { note in
                button(item: .init(label: "Note", value: note, isInteractive: false))
            }
        case .organizations(let organizations):
            FormList(collection: organizations, separator: .invertedNoPadding) { organization in
                button(item: .init(label: "Organization", value: organization, isInteractive: false))
            }
        case .telephones(let telephones):
            FormList(collection: telephones, separator: .invertedNoPadding) { telephone in
                button(item: ContactFormatters.Telephone.formatted(from: telephone)) {
                    // FIXME: Implement call action
                }
            }
        case .photos:
            EmptyView()
        case .roles(let roles):
            FormList(collection: roles, separator: .invertedNoPadding) { role in
                button(item: .init(label: "Role", value: role, isInteractive: false))
            }
        case .timeZones(let timeZones):
            FormList(collection: timeZones, separator: .invertedNoPadding) { timeZone in
                button(item: .init(label: "Time zone", value: timeZone, isInteractive: false))
            }
        case .titles(let titles):
            FormList(collection: titles, separator: .invertedNoPadding) { title in
                button(item: .init(label: "Title", value: title, isInteractive: false))
            }
        case .urls(let urls):
            FormList(collection: urls, separator: .invertedNoPadding) { item in
                button(item: ContactFormatters.URL.formatted(from: item)) {
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

    private func singleButton(item: ContactDetailsItem, action: @escaping () -> Void = {}) -> some View {
        FormBigButton(
            title: item.label.stringResource,
            symbol: .none,
            value: item.value,
            action: action,
            hasAccentTextColor: item.isInteractive
        )
        .disabled(!item.isInteractive)
        .background(DS.Color.BackgroundInverted.secondary)
        .roundedRectangleStyle()
    }

    private func dateField(label: String, from date: ContactDate) -> some View {
        let formattedDate: String
        switch date {
        case .string(let string):
            formattedDate = string
        case .date:
            formattedDate = "N/A"
        }

        let item = ContactDetailsItem(
            label: label,
            value: formattedDate,
            isInteractive: false
        )

        return singleButton(item: item)
    }

    private func addressField(from address: ContactDetailAddress, action: @escaping () -> Void) -> some View {
        let codeAndCity: String = [address.postalCode, address.city]
            .compactMap { $0 }
            .joined(separator: " ")
        let formattedAddress: String = [address.street, codeAndCity]
            .compactMap { $0 }
            .joined(separator: ", ")
        let item = ContactDetailsItem(label: "Address", value: formattedAddress, isInteractive: true)

        return button(item: item, action: action)
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

    static func initial(with contact: ContactItem) -> Self {
        .init(contact: contact, details: .none)
    }

}

enum ContactFormatters {
    enum Telephone {
        static func formatted(from details: ContactDetailsTelephones) -> ContactDetailsItem {
            .init(
                label: details.telTypes.first.map(\.displayType) ?? "Phone",
                value: details.number,
                isInteractive: true
            )
        }
    }

    enum URL {
        static func formatted(from vcardURL: VCardUrl) -> ContactDetailsItem {
            .init(
                label: vcardURL.urlType.first.map(\.displayType) ?? "URL",
                value: vcardURL.url,
                isInteractive: true
            )
        }
    }
}

private extension GenderKind {

    var humanReadable: String {
        switch self {
        case .male:
            "Male"
        case .female:
            "Female"
        case .other:
            "Other"
        case .notApplicable:
            "Not applicable"
        case .unknown:
            "Unknown"
        case .none:
            "None"
        case .string(let string):
            string
        }
    }

}

private extension VcardPropType {

    var displayType: String {
        switch self {
        case .home:
            "Home"
        case .work:
            "Work"
        case .text:
            "Text"
        case .voice:
            "Voice"
        case .fax:
            "Fax"
        case .cell:
            "Cell"
        case .video:
            "Video"
        case .pager:
            "Pager"
        case .textPhone:
            "Text phone"
        case .string(let string):
            string
        }
    }

}
