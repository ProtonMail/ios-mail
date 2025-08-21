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

@MainActor
final class ContactDetailsStateStore: StateStore {
    enum Action {
        case onLoad
        case newMessageTapped
        case callTapped
        case shareTapped
        case phoneNumberTapped(String)
        case editTapped
        case editSheet(EditContactSheetAction)
        case dismissEditSheet
        case emailTapped(ContactDetailsEmail)
        case openURL(urlString: String)
    }

    enum EditContactSheetAction {
        case openSafari
        case dismiss
    }

    @Published var state: ContactDetailsState
    private let env: ApiEnvId
    private let item: ContactDetailsContext
    private let provider: ContactDetailsProvider
    private let urlOpener: URLOpenerProtocol
    private let draftPresenter: ContactsDraftPresenter
    private let toastStateStore: ToastStateStore

    init(
        apiConfig: ApiConfig,
        details: ContactDetails,
        item: ContactDetailsContext,
        provider: ContactDetailsProvider,
        urlOpener: URLOpenerProtocol,
        draftPresenter: ContactsDraftPresenter,
        toastStateStore: ToastStateStore
    ) {
        self.env = apiConfig.envId
        self.state = .initial(details: details)
        self.item = item
        self.provider = provider
        self.urlOpener = urlOpener
        self.draftPresenter = draftPresenter
        self.toastStateStore = toastStateStore
    }

    // MARK: - StateStore

    func handle(action: Action) async {
        switch action {
        case .onLoad:
            await loadDetails(for: item)
        case .newMessageTapped:
            if let primaryEmail = emails.first {
                await openComposer(with: primaryEmail)
            }
        case .callTapped:
            if let phoneNumber = state.details.primaryPhone {
                call(phoneNumber: phoneNumber)
            }
        case .shareTapped:
            toastStateStore.present(toast: .comingSoon)
        case .editTapped:
            state = state.copy(\.displayEditPromptSheet, to: true)
        case .emailTapped(let email):
            await openComposer(with: email)
        case .editSheet(let action):
            state = state.copy(\.displayEditPromptSheet, to: false)

            if case .openSafari = action, let remoteContactID = state.details.remoteID {
                let url: URL = .Contact.edit(domain: env.domain, id: remoteContactID)
                state = state.copy(\.itemToEdit, to: .init(url: url))
            }
        case .dismissEditSheet:
            state = state.copy(\.itemToEdit, to: .none)
        case .phoneNumberTapped(let phoneNumber):
            call(phoneNumber: phoneNumber)
        case .openURL(let urlString):
            if let urlString = normalizedURLString(from: urlString) {
                open(urlString: urlString)
            }
        }
    }

    // MARK: - Private

    private func loadDetails(for contact: ContactDetailsContext) async {
        let details = await provider.contactDetails(for: contact)
        state = state.copy(\.details, to: details)
    }

    private func open(urlString: String) {
        if let url = URL(string: urlString) {
            urlOpener(url)
        }
    }

    private func call(phoneNumber: String) {
        if let url = URL(phoneNumber: phoneNumber) {
            urlOpener(url)
        }
    }

    private func normalizedURLString(from rawString: String) -> String? {
        let url = URL(string: rawString)!
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)

        if urlComponents?.scheme == nil {
            urlComponents?.scheme = "https"
        }

        if urlComponents?.host == nil, urlComponents?.path.isEmpty == false {
            let path = urlComponents?.path
            urlComponents?.host = path
            urlComponents?.path = ""
        }

        return urlComponents?.string
    }

    private func openComposer(with contact: ContactDetailsEmail) async {
        do {
            let recipient = SingleRecipientEntry(name: state.details.displayName, email: contact.email)
            try await draftPresenter.openDraft(with: recipient)
        } catch {
            toastStateStore.present(toast: .error(message: error.localizedDescription))
        }
    }

    private var emails: [ContactDetailsEmail] {
        state.details.items
            .compactMap { item in
                switch item {
                case .emails(let emails):
                    return emails
                default:
                    return nil
                }
            }
            .flatMap { $0 }
    }
}
