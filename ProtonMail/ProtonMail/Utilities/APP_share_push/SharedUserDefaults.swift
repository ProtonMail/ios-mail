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

    private enum Key: String {
        case failedPushNotificationDecryption
    }
}

extension SharedUserDefaults: FailedPushDecryptionMarker {
    func markPushNotificationDecryptionFailure() {
        SystemLogger.log(message: "marked push notification decryption failure", category: .encryption)
        dependencies.userDefaults.set(true, forKey: Key.failedPushNotificationDecryption.rawValue)
    }
}

extension SharedUserDefaults: FailedPushDecryptionProvider {
    var hadPushNotificationDecryptionFailed: Bool {
        dependencies.userDefaults.bool(forKey: Key.failedPushNotificationDecryption.rawValue)
    }

    func clearPushNotificationDecryptionFailure() {
        dependencies.userDefaults.removeObject(forKey: Key.failedPushNotificationDecryption.rawValue)
    }
}

extension SharedUserDefaults {
#if Enterprise
    private static let appGroupUserDefaults = UserDefaults(suiteName: "group.com.protonmail.protonmail")
#else
    private static let appGroupUserDefaults = UserDefaults(suiteName: "group.ch.protonmail.protonmail")
#endif

    struct Dependencies {
        let userDefaults: UserDefaults

        // swiftlint:disable:next force_unwrapping
        init(userDefaults: UserDefaults = SharedUserDefaults.appGroupUserDefaults!) {
            self.userDefaults = userDefaults
        }
    }
}
