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
import ProtonCoreUtilities

final class LockPreventor {
    static let shared = LockPreventor()

    /// Check this variable to know if notifications received to lock the app should be ignored
    private(set) var isLockSuppressed: Bool = false
    private let serialQueue = DispatchQueue(label: "ch.protonmail.protonmail.LockPreventor")

    /// Use this function to execute code that could send a notification to lock the
    /// app (`removedMainKeyFromMemory`), so the app can ignore that notification.
    func performWhileSuppressingLock(block: () -> Void) {
        serialQueue.sync {
            isLockSuppressed = true
            block()
            isLockSuppressed = false
        }
    }
}
