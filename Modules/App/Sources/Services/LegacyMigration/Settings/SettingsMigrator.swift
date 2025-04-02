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

import Foundation
import InboxCore
import proton_app_uniffi

actor SettingsMigrator {
    private let legacyKeychain: LegacyKeychain
    private let legacyDataProvider: LegacyDataProvider

    init(legacyKeychain: LegacyKeychain, legacyDataProvider: LegacyDataProvider) {
        self.legacyKeychain = legacyKeychain
        self.legacyDataProvider = legacyDataProvider
    }

    func migrateSettings(in session: MailSessionProtocol) async {
        let appSettingsDiff = AppSettingsDiff(
            appearance: migrateFromUserDefaults(key: .darkMode),
            autoLock: migrateFromKeychain(key: .autoLockTime),
            useCombineContacts: migrateFromUserDefaults(key: .combineContacts),
            useAlternativeRouting: migrateFromUserDefaults(key: .alternativeRouting)
        )

        do {
            try await session.changeAppSettings(settings: appSettingsDiff).get()
        } catch {
            AppLogger.log(error: error, category: .legacyMigration)
        }
    }

    private func migrateFromKeychain<MigratedValue: LegacyValueConvertible<String>>(
        key: LegacyKeychain.Key
    ) -> MigratedValue? {
        do {
            guard
                let rawValue = try legacyKeychain.string(forKey: key),
                let migratedValue = MigratedValue.init(legacyValue: rawValue)
            else {
                return nil
            }

            return migratedValue
        } catch {
            AppLogger.log(error: error, category: .legacyMigration)
            return nil
        }
    }

    private func migrateFromUserDefaults<MigratedValue: LegacyValueConvertible<RawValue>, RawValue>(
        key: LegacyDataProvider.Key
    ) -> MigratedValue? {
        guard
            let rawValue = legacyDataProvider.object(forKey: key) as? RawValue,
            let migratedValue = MigratedValue.init(legacyValue: rawValue)
        else {
            return nil
        }

        return migratedValue
    }

    private func migrateFromUserDefaults(key: LegacyDataProvider.Key) -> Bool? {
        legacyDataProvider.object(forKey: key) as? Bool
    }
}
