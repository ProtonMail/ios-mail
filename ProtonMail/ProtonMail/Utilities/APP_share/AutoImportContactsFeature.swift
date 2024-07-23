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

import Combine
import Foundation
import ProtonCoreDataModel

final class AutoImportContactsFeature {
    typealias Dependencies = AnyObject
    & HasUserManager
    & HasUserDefaults
    & HasContactsSyncQueueProtocol
    & HasFeatureFlagProvider
    & HasNotificationCenter

    private var userID: UserID {
        dependencies.user.userID
    }
    private unowned var dependencies: Dependencies
    private var cancellables = Set<AnyCancellable>()

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        dependencies
            .contactSyncQueue
            .protonStorageQuotaExceeded
            .sink { [weak self] _ in
                self?.onProtonStorageExcceeded()
            }
            .store(in: &cancellables)
    }

    var isFeatureEnabled: Bool {
        ProcessInfo.isRunningUnitTests
//        let isFFEnabled = dependencies
//            .featureFlagProvider
//            .isEnabled(MailFeatureFlag.autoImportContacts, reloadValue: true)
//        SystemLogger.logTemporarily(message: "isAutoImportContactsFeature enabled \(isFFEnabled)", category: .contacts)
//        return isFFEnabled
    }

    /// This is a value for telemetry.
    /// Returns `nil` if the feature flag is off, otherwise it returns the user setting value.
    var isFeatureEnabledTelemetryValue: Bool? {
        guard dependencies.featureFlagProvider.isEnabled(MailFeatureFlag.autoImportContacts) else {
            return nil
        }
        return isSettingEnabledForUser
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
        postNotificationToCancelImportTask()

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

extension AutoImportContactsFeature {

    private func postNotificationToCancelImportTask() {
        // We have to rely on a notification because ImportDeviceContacts does not
        // exist in Share but this class does and so we can't add the dependency.
        dependencies.notificationCenter.post(name: .cancelImportContactsTask, object: nil)
    }

    private func onProtonStorageExcceeded() {
        SystemLogger.log(message: "Proton quota exceeded", category: .contacts)
        disableSettingAndDeleteQueueForUser()
        DispatchQueue.main.async {
            LocalString._storage_exceeded.alertToastBottom()
        }
    }
}
