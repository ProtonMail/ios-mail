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

import proton_app_uniffi
import ProtonCore
import SwiftUI

final class ContactsStateStore: ObservableObject {
    enum Action {
        case onLoad
    }

    @Published var state: [GroupedContacts]

    private let repository: GroupedContactsProviding

    init(state: [GroupedContacts], repository: GroupedContactsProviding) {
        self.state = state
        self.repository = repository
    }

    func handle(action: Action) {
        switch action {
        case .onLoad:
            Task {
                let contacts = await repository.allContacts()
                let updateStateWorkItem = DispatchWorkItem { [weak self] in
                    self?.state = contacts
                }
                Dispatcher.dispatchOnMain(updateStateWorkItem)
            }
        }
    }
}
