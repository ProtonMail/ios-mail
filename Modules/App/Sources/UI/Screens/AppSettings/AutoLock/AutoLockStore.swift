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
import proton_app_uniffi

class AutoLockStore: StateStore {
    @Published var state: AutoLockState
    private let appSettingsRepository: AppSettingsRepository
    private let router: Router<SettingsRoute>

    init(state: AutoLockState, appSettingsRepository: AppSettingsRepository, router: Router<SettingsRoute>) {
        self.state = state
        self.appSettingsRepository = appSettingsRepository
        self.router = router
    }

    func handle(action: AutoLockAction) async {
        switch action {
        case .optionSelected(let autoLock):
            state = state.copy(\.selectedOption, to: autoLock)
            do {
                try await appSettingsRepository.changeAppSettings(settings: .diff(autoLock: autoLock)).get()
            } catch {
                AppLogger.log(error: error, category: .appSettings)
            }
            router.goBack()
        case .onLoad:
            do {
                let appSettings = try await appSettingsRepository.getAppSettings().get()
                state = state.copy(\.selectedOption, to: appSettings.autoLock)
            } catch {
                AppLogger.log(error: error, category: .appSettings)
            }
        }
    }
}

private extension AppSettingsDiff {
    static func diff(autoLock: AutoLock) -> Self {
        .init(appearance: nil, autoLock: autoLock, useCombineContacts: nil, useAlternativeRouting: nil)
    }
}
