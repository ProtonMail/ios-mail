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
import InboxCore
import Testing

@MainActor
final class AppProtectionSelectionStoreTests {
    private let laContextSpy = LAContextSpy()
    private let router = Router<SettingsRoute>()
    private lazy var appSettingsRepositorySpy = AppSettingsRepositorySpy()
    private lazy var sut = AppProtectionSelectionStore(
        state: .initial,
        router: router,
        appSettingsRepository: appSettingsRepositorySpy,
        laContext: { [unowned self] in self.laContextSpy }
    )

    @Test
    func whenViewAppears_ItLoadsSupportedProtectionTypes() async {
        await sut.handle(action: .onAppear)
        #expect(
            sut.state.availableAppProtectionMethods == [
                .init(type: .none, isSelected: false),
                .init(type: .pin, isSelected: true),
                .init(type: .faceID, isSelected: false),
            ]
        )
        #expect(sut.state.selectedAppProtection == .pin)
    }

    @Test
    func whenCurrentProtectionIsBiometricAndPINOptionIsSelected_ItTriggersSetPINFlow() async {
        appSettingsRepositorySpy.stubbedAppSettings = appSettingsRepositorySpy.stubbedAppSettings
            .copy(\.protection, to: .biometrics)

        await sut.handle(action: .onAppear)
        await sut.handle(action: .selected(.pin))

        #expect(sut.state.presentedPINScreen == .set)
    }

    @Test
    func whenCurrentProtectionIsPINAndPINOptionIsSelected_ItDoesNotTriggerSetPINFlow() async {
        await sut.handle(action: .onAppear)
        await sut.handle(action: .selected(.pin))

        #expect(router.stack == [])
    }
}
