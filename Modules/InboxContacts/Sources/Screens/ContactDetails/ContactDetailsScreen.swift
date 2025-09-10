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
    let contact: ContactDetailsContext
    private let apiConfig: ApiConfig
    private let provider: ContactDetailsProvider
    private let draftPresenter: ContactsDraftPresenter
    private let initialState: ContactDetails?
    @Environment(\.openURL) private var urlOpener
    @EnvironmentObject private var toastStateStore: ToastStateStore

    /// `state` parameter is exposed only for testing purposes to be able to rely on data source in synchronous manner.
    init(
        apiConfig: ApiConfig,
        contact: ContactDetailsContext,
        provider: ContactDetailsProvider,
        draftPresenter: ContactsDraftPresenter,
        state: ContactDetails? = nil
    ) {
        self.apiConfig = apiConfig
        self.contact = contact
        self.provider = provider
        self.draftPresenter = draftPresenter
        self.initialState = state
    }

    var body: some View {
        StoreView(
            store: ContactDetailsStateStore(
                apiConfig: apiConfig,
                details: initialState ?? .initial(with: contact),
                item: contact,
                provider: provider,
                urlOpener: urlOpener,
                draftPresenter: draftPresenter,
                toastStateStore: toastStateStore
            )
        ) { state, store in
            ScrollView {
                VStack(spacing: DS.Spacing.large) {
                    avatarView(state: state)
                    contactDetails(state: state)
                    actionButtons(state: state, store: store)
                    fields(state: state, store: store)
                }
                .padding([.horizontal, .bottom], DS.Spacing.large)
            }
            .background(DS.Color.Background.secondary)
            .toolbar {
                if state.details.remoteID != nil {
                    ToolbarItemFactory.trailing(L10n.ContactDetails.edit.string) {
                        store.handle(action: .editTapped)
                    }
                }
            }
            .sheet(
                isPresented: displayEditSheet(store: store, state: state),
                content: {
                    PromptSheet(
                        model: .editInWeb(
                            onAction: { store.handle(action: .editSheet(.openSafari)) },
                            onDismiss: { store.handle(action: .editSheet(.dismiss)) }
                        )
                    )
                }
            )
            .sheet(
                item: itemToEdit(store: store, state: state),
                onDismiss: { store.handle(action: .dismissEditSheet) },
                content: SafariView.init
            )
            .onLoad { store.handle(action: .onLoad) }
        }
    }

    // MARK: - Private

    private func avatarView(state: ContactDetailsStateStore.State) -> some View {
        ContactAvatarView(hexColor: state.details.avatarInformation.color) {
            Text(state.details.avatarInformation.text)
                .font(.title)
                .fontWeight(.regular)
                .foregroundStyle(DS.Color.Text.inverted)
        }
    }

    private func contactDetails(state: ContactDetailsState) -> some View {
        ContactAvatarDetailsView(title: state.details.displayName, subtitle: state.details.primaryEmail)
    }

    private func actionButtons(
        state: ContactDetailsStateStore.State,
        store: ContactDetailsStateStore
    ) -> some View {
        HStack(spacing: DS.Spacing.standard) {
            ContactDetailsActionButton(
                image: DS.Icon.icPenSquare,
                title: L10n.ContactDetails.newMessage,
                disabled: state.details.primaryEmail == nil,
                action: { store.handle(action: .newMessageTapped) }
            )
            ContactDetailsActionButton(
                image: DS.Icon.icPhone,
                title: L10n.ContactDetails.call,
                disabled: state.details.primaryPhone == nil,
                action: { store.handle(action: .callTapped) }
            )
            ContactDetailsActionButton(
                image: DS.Icon.icArrowUpFromSquare,
                title: L10n.ContactDetails.share,
                disabled: false,
                action: { store.handle(action: .shareTapped) }
            )
        }
    }

    private func fields(state: ContactDetailsState, store: ContactDetailsStateStore) -> some View {
        ForEach(state.details.items, id: \.self) { item in
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
            FormList(collection: emails) { email in
                button(item: ContactFormatter.Email.formatted(from: email)) {
                    store.handle(action: .emailTapped(email))
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
                    store.handle(action: .phoneNumberTapped(telephone.number))
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
                    if let urlString = item.url.urlString {
                        store.handle(action: .openURL(urlString: urlString))
                    }
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

    private func singleButton(item: ContactDetailsItem) -> some View {
        button(item: item, action: {})
            .background(DS.Color.BackgroundInverted.secondary)
            .roundedRectangleStyle()
    }

    private func displayEditSheet(store: ContactDetailsStateStore, state: ContactDetailsState) -> Binding<Bool> {
        .init(
            get: { state.displayEditPromptSheet },
            set: { newValue in store.state = store.state.copy(\.displayEditPromptSheet, to: newValue) }
        )
    }

    private func itemToEdit(store: ContactDetailsStateStore, state: ContactDetailsState) -> Binding<SafariDetails?> {
        .init(
            get: { state.itemToEdit },
            set: { newState in store.state = state.copy(\.itemToEdit, to: newState) }
        )
    }
}

private extension ContactDetails {

    static func initial(with contact: ContactDetailsContext) -> Self {
        .init(contact: contact, details: .none)
    }

}

private extension FormList {

    init(collection: Collection, elementContent: @escaping (Collection.Element) -> ElementContent) {
        self.init(collection: collection, separator: .invertedNoPadding, elementContent: elementContent)
    }

}

private extension VCardUrlValue {

    var urlString: String? {
        switch self {
        case .http(let string):
            string
        case .notHttp, .text:
            nil
        }
    }

}

#Preview {
    ContactDetailsScreen(
        apiConfig: .debugPreview,
        contact: ContactItem(
            id: .random(),
            name: .empty,
            avatarInformation: .init(text: "BA", color: "#3357FF"),
            emails: []
        ),
        provider: .previewInstance(),
        draftPresenter: ContactsDraftPresenterDummy()
    )
}
