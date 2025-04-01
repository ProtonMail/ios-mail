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

import proton_app_uniffi
import Testing

final class SettingsMigratorTests {
    private let legacyKeychain = LegacyKeychain.randomInstance()
    private let testUserDefaults = TestableUserDefaults.randomInstance()
    private let mailSession = MailSessionSpy()

    private lazy var sut = SettingsMigrator(
        legacyKeychain: legacyKeychain,
        legacyDataProvider: .init(userDefaults: testUserDefaults)
    )

    deinit {
        legacyKeychain.removeEverything()
        testUserDefaults.removeSuite(named: testUserDefaults.suiteName)
    }

    @Test("migrates AppAppearance", arguments: zip([0, 1, 2], [AppAppearance.system, .darkMode, .lightMode]))
    func migratesAppAppearance(legacyValue: Int, as expectedMigratedValue: AppAppearance) async throws {
        testUserDefaults.set(legacyValue, forKey: .darkMode)

        await sut.migrateSettings(in: mailSession)

        let settingsUpdate = try #require(mailSession.changeAppSettingsInvocations.first)
        #expect(settingsUpdate.appearance == expectedMigratedValue)
    }

    @Test("migrates AutoLock", arguments: zip(["-1", "0", "30"], [nil, AutoLock.always, .minutes(30)]))
    func migratesAutoLock(legacyValue: String, as expectedMigratedValue: AutoLock?) async throws {
        try legacyKeychain.set(legacyValue, forKey: .autoLockTime)

        await sut.migrateSettings(in: mailSession)

        let settingsUpdate = try #require(mailSession.changeAppSettingsInvocations.first)
        #expect(settingsUpdate.autoLock == expectedMigratedValue)
    }

    @Test("migrates Use Combine Contacts", arguments: [true, false])
    func migratesCombineContacts(legacyValue: Bool) async throws {
        testUserDefaults.set(legacyValue, forKey: .combineContacts)

        await sut.migrateSettings(in: mailSession)

        let settingsUpdate = try #require(mailSession.changeAppSettingsInvocations.first)
        #expect(settingsUpdate.useCombineContacts == legacyValue)
    }

    @Test("migrates Use Alternative Routing", arguments: [true, false])
    func migratesAlternativeRouting(legacyValue: Bool) async throws {
        testUserDefaults.set(legacyValue, forKey: .alternativeRouting)

        await sut.migrateSettings(in: mailSession)

        let settingsUpdate = try #require(mailSession.changeAppSettingsInvocations.first)
        #expect(settingsUpdate.useAlternativeRouting == legacyValue)
    }

    @Test
    func doesNotOverrideSettingsThatWereNeverCustomized() async throws {
        await sut.migrateSettings(in: mailSession)

        let settingsUpdate = try #require(mailSession.changeAppSettingsInvocations.first)

        let expectedSettingsUpdate = AppSettingsDiff(
            appearance: nil,
            autoLock: nil,
            useCombineContacts: nil,
            useAlternativeRouting: nil
        )

        #expect(settingsUpdate == expectedSettingsUpdate)
    }
}
