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
import InboxIAP
import SwiftUI

@MainActor
class SnoozeStore: StateStore {
    @Published var state: SnoozeState
    private let upsellScreenPresenter: UpsellScreenPresenter
    private let toastStateStore: ToastStateStore

    init(state: SnoozeState, upsellScreenPresenter: UpsellScreenPresenter, toastStateStore: ToastStateStore) {
        self.state = state
        self.upsellScreenPresenter = upsellScreenPresenter
        self.toastStateStore = toastStateStore
    }

    func handle(action: SnoozeViewAction) async {
        switch action {
        case .customButtonTapped:
            transition(to: .custom)
        case .upgradeTapped:
            do {
                let upsellScreenModel = try await upsellScreenPresenter.presentUpsellScreen(entryPoint: .snooze)
                state = state.copy(\.presentUpsellScreen, to: upsellScreenModel)
            } catch {
                toastStateStore.present(toast: .error(message: error.localizedDescription))
            }
        case .predefinedSnoozeOptionTapped:
            break
        case .unsnoozeTapped:
            break
        case .customSnoozeCancelTapped:
            transition(to: .main)
        }
    }

    private func transition(to screen: SnoozeView.Screen) {
        withAnimation {
            state =
                state
                .copy(\.screen, to: screen)
                .copy(\.allowedDetents, to: screen.allowedDetents)
                .copy(\.currentDetent, to: screen.detent)
        } completion: { [weak self] in
            guard let self else { return }
            self.state = self.state
                .copy(\.allowedDetents, to: [screen.detent])
        }
    }

}

extension SnoozeView.Screen {

    var detent: PresentationDetent {
        switch self {
        case .custom:
            .large
        case .main:
            .medium
        }
    }

    var allowedDetents: Set<PresentationDetent> {
        Set(Self.allCases.map(\.detent))
    }

}
