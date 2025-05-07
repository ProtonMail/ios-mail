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

import SwiftUI
import InboxCore

class ConfirmPINStore: StateStore {
    @Published var state: ConfirmPINState
    private let router: Router<SettingsRoute>

    init(state: ConfirmPINState, router: Router<SettingsRoute>) {
        self.state = state
        self.router = router
    }

    func handle(action: ConfirmPINAction) async {
        switch action {
        case .pinTyped(let repeatedPIN):
            state = state
                .copy(\.repeatedPIN, to: repeatedPIN)
                .copy(\.repeatedPINValidation, to: .ok)
        case .confirmButtonTapped:
            let doesPINMatch = state.pin == state.repeatedPIN
            state = state
                .copy(\.repeatedPINValidation, to: doesPINMatch ? .ok : .failure("The PIN codes must match!"))
            router.goBack(to: .appProtection(.pin)) // FIXME: - Remove associated value
        }
    }
}
