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

enum AutoDeleteSpamAndTrashDays {
    case implicitlyDisabled
    case explicitlyDisabled
    case explicitlyEnabled

    static let disabledValue: Int = 0
    static let enabledValue: Int = 30

    init(rawValue: Int?) {
        guard let rawValue else {
            self = .implicitlyDisabled
            return
        }
        if rawValue == 0 {
            self = .explicitlyDisabled
        } else {
            self = .explicitlyEnabled
        }
    }

    var isEnabled: Bool {
        switch self {
        case .implicitlyDisabled, .explicitlyDisabled:
            return false
        case .explicitlyEnabled:
            return true
        }
    }
}

extension AutoDeleteSpamAndTrashDays: Encodable {
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .implicitlyDisabled:
            try container.encodeNil()
        case .explicitlyDisabled:
            try container.encode(Self.disabledValue)
        case .explicitlyEnabled:
            try container.encode(Self.enabledValue)
        }
    }
}
