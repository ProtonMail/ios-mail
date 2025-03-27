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
import SwiftUI

class PINLockStateStore: StateStore {
    @Published var state: PINLockState
    private let output: (PINLockScreenOutput) -> Void

    init(state: PINLockState, output: @escaping (PINLockScreenOutput) -> Void) {
        self.state = state
        self.output = output
    }

    @MainActor
    func handle(action: PINLockScreenAction) {
        switch action {
        case .keyboardTapped(let button):
            handle(buttonTap: button)
        case .confirmTapped:
            guard !state.pin.isEmpty else { return }
            output(.pin(state.pin))
            state = state.copy(\.pin, to: .empty)
        case .signOutTapped:
            let alert: AlertViewModel = .logOutConfirmation(
                action: { [weak self] action in self?.handle(action: .alertActionTapped(action)) }
            )
            state = state.copy(\.alert, to: alert)
        case .alertActionTapped(let action):
            state.alert = nil
            handleAlert(action: action)
        case .error(let error):
            state = state.copy(\.error, to: error)
        }
    }

    @MainActor
    private func handleAlert(action: LogOutConformationAction) {
        switch action {
        case .signOut:
            output(.logOut)
        case .cancel:
            break
        }
    }

    @MainActor
    private func handle(buttonTap: PINLockScreen.KeyboardButton) {
        switch buttonTap {
        case .digit(let value):
            state = state
                .copy(\.pin, to: state.pin.appending("\(value)"))
                .copy(\.error, to: nil)
        case .delete:
            state = state
                .copy(\.pin, to: String(state.pin.dropLast()))
                .copy(\.error, to: nil)
        }
    }
}

extension AlertViewModel {
    
    static func logOutConfirmation(action: @escaping (LogOutConformationAction) -> Void) -> AlertViewModel {
        let actions: [AlertAction] = LogOutConformationAction.allCases.map { actionType in
            .init(details: actionType, action: { action(actionType) })
        }
        
        return .init(
            title: L10n.PINLock.signOutConfirmationTitle,
            message: nil,
            actions: actions
        )
    }
    
}
