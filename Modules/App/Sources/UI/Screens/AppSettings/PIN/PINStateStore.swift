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

class PINStateStore: StateStore {
    @Published var state: PINScreenState
    private let pinScreenValidator: PINValidator
    private let pinActionPerformer: PINActionPerformer
    private let router: Router<SettingsRoute>

    init(state: PINScreenState, router: Router<SettingsRoute>) {
        self.state = state
        self.pinScreenValidator = .init(pinScreenType: state.type)
        self.pinActionPerformer = PINActionPerformer()
        self.router = router
    }

    @MainActor
    func handle(action: PINScreenAction) async {
        switch action {
        case .pinTyped(let pin):
            state = state.copy(\.pin, to: pin)
                .copy(\.pinValidation, to: .ok)
        case .trailingButtonTapped:
            state = state.copy(\.pinValidation, to: pinScreenValidator.validate(pin: state.pin))
            if state.pinValidation.isSuccess {
                switch state.type {
                case .set(let oldPIN):
                    if let oldPIN {
                        router.go(to: .pin(type: .change(oldPIN: oldPIN, newPIN: state.pin)))
                    } else {
                        router.go(to: .pin(type: .confirm(pin: state.pin)))
                    }
                case .confirm(let pin):
                    await pinActionPerformer.perform(action: .set(pin: pin))
                    router.go(to: .appProtection)
                case .change(let oldPIN, let newPIN):
                    await pinActionPerformer.perform(action: .change(oldPIN: oldPIN, newPIN: newPIN))
                    router.go(to: .appProtection)
                case .verify(let flow):
                    await pinActionPerformer.perform(action: .verify(pin: state.pin))
                    switch flow {
                    case .changePIN:
                        router.go(to: .pin(type: .set(oldPIN: state.pin)))
                    case .verify:
                        router.go(to: .appProtection)
                    }
                }
            }
        }
    }
}
