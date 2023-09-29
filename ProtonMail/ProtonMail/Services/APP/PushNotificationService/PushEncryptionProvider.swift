// Copyright (c) 2023 Proton Technologies AG
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

protocol PushEncryptionProvider: AnyObject {

    var isDeviceTokenRegistrationRetryPending: Bool { get set }
    var lastRegisteredDeviceToken: String? { get set }
}

extension UserDefaults: PushEncryptionProvider {

    private enum Keys {
        static let retryTokenRegistration = "pushEncryptionRetryDeviceTokenRegistration"
        static let lastRegisteredDeviceToken = "pushEncryptionLastRegisteredDeviceToken"
    }

    var isDeviceTokenRegistrationRetryPending: Bool {
        get {
            bool(forKey: Keys.retryTokenRegistration)
        }
        set {
            set(newValue, forKey: Keys.retryTokenRegistration)
        }
    }

    var lastRegisteredDeviceToken: String? {
        get {
            string(forKey: Keys.lastRegisteredDeviceToken)
        }
        set {
            set(newValue, forKey: Keys.lastRegisteredDeviceToken)
        }
    }
}
