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
import proton_app_uniffi
import SwiftUI

@MainActor
final class ContactGroupDetailsStateStore: StateStore {
    enum Action {
        case contactItemTapped(ContactEmailItem)
        case sendGroupMessageTapped
    }

    @Published var state: ContactGroupItem
    private let draftPresenter: ContactsDraftPresenter
    private let toastStateStore: ToastStateStore
    private let router: Router<ContactsRoute>

    init(
        state: ContactGroupItem,
        draftPresenter: ContactsDraftPresenter,
        toastStateStore: ToastStateStore,
        router: Router<ContactsRoute>
    ) {
        self.state = state
        self.draftPresenter = draftPresenter
        self.toastStateStore = toastStateStore
        self.router = router
    }

    func handle(action: Action) async {
        switch action {
        case .contactItemTapped(let item):
            router.go(to: .contactDetails(.init(item)))
        case .sendGroupMessageTapped:
            await openComposer(with: state)
        }
    }

    private func openComposer(with group: ContactGroupItem) async {
        do {
            try await draftPresenter.openDraft(with: group)
        } catch {
            toastStateStore.present(toast: .error(message: error.localizedDescription))
        }
    }
}
