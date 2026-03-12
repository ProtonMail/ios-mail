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

import CoreLogger
import InboxCore

enum CoreLoggerBridge {
    /// Forwards `CoreLogger` entries into `AppLogger` (and therefore into the SDK log file).
    /// Call once at app startup, before any CoreLogger calls occur.
    static func setUp() {
        CoreLogger.onLog = { message, category, isError in
            let prefixed = category.map { "\($0.rawValue): \(message)" } ?? message
            AppLogger.log(message: prefixed, isError: isError)
        }
    }
}
