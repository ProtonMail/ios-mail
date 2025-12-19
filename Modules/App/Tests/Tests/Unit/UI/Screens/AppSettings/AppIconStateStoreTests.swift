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

import Testing

@testable import ProtonMail

@MainActor
class AppIconStateStoreTests {
    private let appIconConfiguratorSpy = AppIconConfiguratorSpy()

    @Test
    func whenIconIsTapped_AndItsDifferentFromCurrent_ItChangesToNewIcon() async {
        let sut = setUpSUT(appIcon: .default)

        let newIcon = AppIcon.notes
        await sut.handle(action: .iconTapped(icon: newIcon))

        #expect(sut.state.appIcon == newIcon)
        #expect(appIconConfiguratorSpy.setAlternateIconNameCalls == [newIcon.alternateIconName])
    }

    @Test
    func whenIconIsTapped_AndItsSameAsCurrent_ItDoesNothing() async {
        let icon = AppIcon.notes
        let sut = setUpSUT(appIcon: icon)

        await sut.handle(action: .iconTapped(icon: icon))

        #expect(sut.state.appIcon == icon)
        #expect(appIconConfiguratorSpy.setAlternateIconNameCalls.isEmpty)
    }

    @Test
    func whenDiscreetModeIsEnabled_ItSetsToFirstAlternateIcon() async {
        let sut = setUpSUT(appIcon: .default)

        await sut.handle(action: .discreetAppIconSwitched(isEnabled: true))

        let newIcon = AppIcon.alternateIcons.first!
        #expect(sut.state == AppIconState(appIcon: newIcon, isDiscreetAppIconOn: true))
        #expect(appIconConfiguratorSpy.setAlternateIconNameCalls == [newIcon.alternateIconName])
    }

    @Test
    func whenDiscreetModeIsDisabled_ItSetsToDefaultIcon() async {
        let sut = setUpSUT(appIcon: .notes)

        await sut.handle(action: .discreetAppIconSwitched(isEnabled: false))

        #expect(sut.state == AppIconState(appIcon: .default, isDiscreetAppIconOn: false))
        #expect(appIconConfiguratorSpy.setAlternateIconNameCalls == [nil])
    }

    // MARK: - Private

    private func setUpSUT(appIcon: AppIcon) -> AppIconStateStore {
        AppIconStateStore(
            state: .initial(appIcon: appIcon),
            appIconConfigurator: appIconConfiguratorSpy
        )
    }
}
