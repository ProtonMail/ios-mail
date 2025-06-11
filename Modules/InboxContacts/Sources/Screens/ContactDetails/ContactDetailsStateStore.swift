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
        case call(phoneNumber: String)
        case onLoad
        case openURL(urlString: String)
    }

    @Published var state: ContactDetails
    private let item: ContactItem
    private let provider: ContactDetailsProvider
    private let urlOpener: URLOpenerProtocol

    init(
        state: ContactDetails,
        item: ContactItem,
        provider: ContactDetailsProvider,
        urlOpener: URLOpenerProtocol
    ) {
        self.state = state
        self.item = item
        self.provider = provider
        self.urlOpener = urlOpener
    }

    // MARK: - StateStore

    @MainActor
    func handle(action: Action) {
        switch action {
        case .onLoad:
            loadDetails(for: item)
        case .call(let phoneNumber):
            open(urlString: "tel://\(phoneNumber)")
        case .openURL(let urlString):
            open(urlString: urlString)
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
}
