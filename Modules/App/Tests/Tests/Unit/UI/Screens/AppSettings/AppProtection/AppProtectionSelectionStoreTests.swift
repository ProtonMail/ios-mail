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

@testable import ProtonMail
import Testing

class AppProtectionSelectionStoreTests {

    var sut: AppProtectionSelectionStore!
    var laContextSpy: LAContextSpy!

    init() {
        laContextSpy = .init()
        sut = .init(
            state: .initial(appProtection: .biometrics),
            laContext: { self.laContextSpy }
        )
    }

    @Test
    func whenViewIsLoaded_ItLoadsSupportedProtectionTypes() async {
        await sut.handle(action: .viewLoads)
        #expect(sut.state.availableAppProtectionMethods == [
            .init(type: .none, isSelected: false),
            .init(type: .pin, isSelected: false),
            .init(type: .faceID, isSelected: true)
        ])
        #expect(sut.state.selectedAppProtection == .biometrics)
    }

    @Test
    func whenPINOptionIsSelected_ItMarksPINAsSelectedProtectionMethod() async {
        await sut.handle(action: .viewLoads)
        await sut.handle(action: .selected(.pin))

        #expect(sut.state.availableAppProtectionMethods == [
            .init(type: .none, isSelected: false),
            .init(type: .pin, isSelected: true),
            .init(type: .faceID, isSelected: false)
        ])
        #expect(sut.state.selectedAppProtection == .pin)
    }

}
