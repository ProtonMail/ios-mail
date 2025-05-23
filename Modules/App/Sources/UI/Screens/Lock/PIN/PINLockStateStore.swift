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
    func handle(action: PINLockScreenAction) async {
        switch action {
        case .confirmTapped:
            output(.pin(state.pin))
        case .signOutTapped:
            let alert: AlertModel = .logOutConfirmation(
                action: { [weak self] action in self?.handle(action: .alertActionTapped(action)) }
            )
            state = state.copy(\.alert, to: alert)
        case .pinEntered(let pin):
            state =
                state
                .copy(\.pin, to: pin)
                .copy(\.error, to: nil)
        case .alertActionTapped(let action):
            state.alert = nil
            handleAlert(action: action)
        case .error(let error):
            state =
                state
                .copy(\.error, to: error)
                .copy(\.pin, to: [])
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

}

extension AlertModel {

    static func logOutConfirmation(action: @escaping (LogOutConformationAction) async -> Void) -> Self {
        let actions: [AlertAction] = LogOutConformationAction.allCases.map { actionType in
            .init(details: actionType, action: { await action(actionType) })
        }

        return .init(
            title: L10n.PINLock.signOutConfirmationTitle,
            message: nil,
            actions: actions
        )
    }

}
