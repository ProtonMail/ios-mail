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

final class ContactDetailsStateStore: StateStore {
    enum Action {
        case onLoad
        case newMessageTapped
        case callTapped
        case shareTapped
        case phoneNumberTapped(String)
        case emailTapped(ContactDetailsEmail)
        case openURL(urlString: String)
    }

    @Published var state: ContactDetails
    private let item: ContactItem
    private let provider: ContactDetailsProvider
    private let urlOpener: URLOpenerProtocol
    private let draftPresenter: ContactsDraftPresenter
    private let toastStateStore: ToastStateStore

    init(
        state: ContactDetails,
        item: ContactItem,
        provider: ContactDetailsProvider,
        urlOpener: URLOpenerProtocol,
        draftPresenter: ContactsDraftPresenter,
        toastStateStore: ToastStateStore
    ) {
        self.state = state
        self.item = item
        self.provider = provider
        self.urlOpener = urlOpener
        self.draftPresenter = draftPresenter
        self.toastStateStore = toastStateStore
    }

    // MARK: - StateStore

    @MainActor
    func handle(action: Action) {
        switch action {
        case .onLoad:
            loadDetails(for: item)
        case .newMessageTapped:
            if let primaryEmail = emails.first {
                openComposer(with: primaryEmail)
            }
        case .callTapped:
            if let phoneNumber = state.primaryPhone {
                call(phoneNumber: phoneNumber)
            }
        case .shareTapped:
            toastStateStore.present(toast: .comingSoon)
        case .emailTapped(let email):
            openComposer(with: email)
        case .phoneNumberTapped(let phoneNumber):
            call(phoneNumber: phoneNumber)
        case .openURL(let urlString):
            if let urlString = normalizedURLString(from: urlString) {
                open(urlString: urlString)
            }
        }
    }

    // MARK: - Private

    private func loadDetails(for contact: ContactItem) {
        Task {
            let details = await provider.contactDetails(for: contact)
            let updateStateWorkItem = DispatchWorkItem { [weak self] in
                self?.state = details
            }

            Dispatcher.dispatchOnMain(updateStateWorkItem)
        }
    }

    private func open(urlString: String) {
        if let url = URL(string: urlString) {
            urlOpener(url)
        }
    }

    private func call(phoneNumber: String) {
        open(urlString: "tel:\(phoneNumber)")
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

    private func openComposer(with contact: ContactDetailsEmail) {
        Task {
            do {
                let recipient = SingleRecipientEntry(name: state.displayName, email: contact.email)
                try await draftPresenter.openDraft(with: recipient)
            } catch {
                toastStateStore.present(toast: .error(message: error.localizedDescription))
            }
        }
    }

    private var emails: [ContactDetailsEmail] {
        state.items
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
