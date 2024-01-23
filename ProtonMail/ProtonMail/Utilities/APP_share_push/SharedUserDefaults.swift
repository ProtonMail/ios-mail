// Copyright (c) 2021 Proton AG
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

// sourcery: mock
protocol FailedPushDecryptionMarker {
    func markPushNotificationDecryptionFailure()
}

// sourcery: mock
protocol FailedPushDecryptionProvider {
    var hadPushNotificationDecryptionFailed: Bool { get }

    func clearPushNotificationDecryptionFailure()
}

struct SharedUserDefaults {
    static let shared = SharedUserDefaults()
    private let dependencies: Dependencies

    init(dependencies: Dependencies = .init()) {
        self.dependencies = dependencies
    }
}

extension SharedUserDefaults: FailedPushDecryptionMarker {
    func markPushNotificationDecryptionFailure() {
        SystemLogger.log(message: "marked push notification decryption failure", category: .encryption)
        dependencies.userDefaults[.failedPushNotificationDecryption] = true
    }
}

extension SharedUserDefaults: FailedPushDecryptionProvider {
    var hadPushNotificationDecryptionFailed: Bool {
        dependencies.userDefaults[.failedPushNotificationDecryption] ?? false
    }

    func clearPushNotificationDecryptionFailure() {
        dependencies.userDefaults[.failedPushNotificationDecryption] = nil
    }
}

extension SharedUserDefaults: PushCacheStatus {
    var primaryUserSessionId: String? {
        get {
            dependencies.userDefaults[.primaryUserSessionId]
        }
        set {
            dependencies.userDefaults[.primaryUserSessionId] = newValue
        }
    }
}

extension SharedUserDefaults {
    struct Dependencies {
        let userDefaults: UserDefaults

        // swiftlint:disable:next force_unwrapping
        init(userDefaults: UserDefaults = UserDefaults(suiteName: Constants.AppGroup)!) {
            self.userDefaults = userDefaults
        }
    }
}
