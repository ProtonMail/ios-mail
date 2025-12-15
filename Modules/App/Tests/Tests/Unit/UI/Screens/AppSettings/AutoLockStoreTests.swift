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
import Testing
import proton_app_uniffi

@testable import ProtonMail

@MainActor
class AutoLockStoreTests {
    let appSettingsRepositorySpy = AppSettingsRepositorySpy()
    let router = Router<SettingsRoute>()
    lazy var sut = AutoLockStore(
        state: .init(),
        appSettingsRepository: appSettingsRepositorySpy,
        router: router
    )

    init() {
        appSettingsRepositorySpy.stubbedAppSettings = appSettingsRepositorySpy.stubbedAppSettings
            .copy(\.autoLock, to: .always)
    }

    @Test
    func screenIsLoaded_ItLoadsData() async {
        #expect(sut.state.selectedOption == nil)

        await sut.handle(action: .onLoad)

        #expect(sut.state.selectedOption == .always)
    }

    @Test
    func screenIsLoadedAndOption10MinutesIsSelected_ItUpdatesSettingsAndGoesBack() async {
        router.stack = [.appProtection, .autoLock]
        await sut.handle(action: .onLoad)
        await sut.handle(action: .optionSelected(.minutes(10)))

        #expect(sut.state.selectedOption == .minutes(10))
        #expect(router.stack == [.appProtection])
    }
}
