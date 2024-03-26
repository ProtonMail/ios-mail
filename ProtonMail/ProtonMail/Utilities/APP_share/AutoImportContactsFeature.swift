// Copyright (c) 2024 Proton Technologies AG
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
import ProtonCoreDataModel

struct AutoImportContactsFeature {
    typealias Dependencies = AnyObject
    & HasUserManager
    & HasUserDefaults
    & HasContactsSyncQueueProtocol
    & HasFeatureFlagProvider

    private var userID: UserID {
        dependencies.user.userID
    }
    private unowned var dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    var isFeatureEnabled: Bool {
        false
//      dependencies.featureFlagProvider.isEnabled(MailFeatureFlag.autoImportContacts, reloadValue: true)
    }

    var shouldImportContacts: Bool {
        isFeatureEnabled && isSettingEnabledForUser
    }

    var isSettingEnabledForUser: Bool {
        let autoImportFlags = dependencies.userDefaults[.isAutoImportContactsOn]
        return autoImportFlags[userID.rawValue] ?? false
    }

    func enableSettingForUser() {
        var autoImportFlags = dependencies.userDefaults[.isAutoImportContactsOn]
        autoImportFlags[userID.rawValue] = true
        dependencies.userDefaults[.isAutoImportContactsOn] = autoImportFlags
        let message = "Auto import contacts enabled for user \(userID.rawValue.redacted)"
        SystemLogger.log(message: message, category: .contacts)
    }

    func disableSettingForUser() {
        var historyTokens = dependencies.userDefaults[.contactsHistoryTokenPerUser]
        historyTokens[userID.rawValue] = nil
        dependencies.userDefaults[.contactsHistoryTokenPerUser] = historyTokens

        var autoImportFlags = dependencies.userDefaults[.isAutoImportContactsOn]
        autoImportFlags[userID.rawValue] = nil
        dependencies.userDefaults[.isAutoImportContactsOn] = autoImportFlags
        let message = "Auto import contacts disabled for user \(userID.rawValue.redacted)"
        SystemLogger.log(message: message, category: .contacts)
    }

    func disableSettingAndDeleteQueueForUser() {
        disableSettingForUser()
        dependencies.contactSyncQueue.deleteQueue()
    }
}
