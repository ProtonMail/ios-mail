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

import Combine
import InboxCoreUI

class AppIconStateStore: StateStore {
    @Published var state: AppIconState
    private let appIconConfigurator: AppIconConfigurable

    init(state: AppIconState, appIconConfigurator: AppIconConfigurable) {
        self.state = state
        self.appIconConfigurator = appIconConfigurator
    }

    func handle(action: AppIconScreenAction) async {
        switch action {
        case .iconTapped(let icon):
            guard icon != state.appIcon else { return }
            await changeIcon(to: icon)
        case .discreetAppIconSwitched(let isEnabled):
            let icon = (isEnabled ? AppIcon.alternateIcons.first : nil) ?? .default
            await changeIcon(to: icon)
        }
    }

    private func changeIcon(to appIcon: AppIcon) async {
        state = state.copy(\.appIcon, to: appIcon)
        try? await appIconConfigurator.setAlternateIconName(appIcon.alternateIconName)
    }
}
