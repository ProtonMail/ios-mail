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

class SnoozeStore: StateStore {
    @Published var state: SnoozeState

    init(state: SnoozeState) {
        self.state = state
    }

    @MainActor
    func handle(action: SnoozeViewAction) async {
        switch action {
        case .transtion(let screen):
            withAnimation {
                state = state
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
}
