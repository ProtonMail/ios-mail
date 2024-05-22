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

import ProtonCoreKeymaker

// sourcery: mock
protocol LockCacheStatus {
    var isPinCodeEnabled: Bool { get }
    var isTouchIDEnabled: Bool { get }
    var isAppKeyEnabled: Bool { get }

    /// Returns `true` if there is some kind of protection to access the app, and
    /// the main key is only accessible if user interacts to unlock the app (e.g. enters pin, uses FaceID,...)
    var isAppLockedAndAppKeyEnabled: Bool { get }
}

extension Keymaker: LockCacheStatus {
    var isPinCodeEnabled: Bool {
        isProtectorActive(PinProtection.self)
    }

    var isTouchIDEnabled: Bool {
        isProtectorActive(BioProtection.self)
    }

    var isAppKeyEnabled: Bool {
        if isProtectorActive(RandomPinProtection.self) || isProtectorActive(NoneProtection.self) {
            return false
        } else {
            return true
        }
    }

    var isAppLockedAndAppKeyEnabled: Bool {
        return isAppLockEnabled && isAppKeyEnabled
    }

    private var isAppLockEnabled: Bool {
        return (isTouchIDEnabled || isPinCodeEnabled)
    }
}
