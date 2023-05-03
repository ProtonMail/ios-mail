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

/// For mail setting - `Keep messages in Sent/Drafts`
enum ShowMoved: Int, Codable {
    case doNotKeep = 0
    /// keep draft messages in Draft folder
    case keepDraft = 1
    /// keep sent messages in Sent folder
    case keepSent = 2
    /// keep both draft and sent messages in their respective folders
    case keepBoth = 3

    init(rawValue: Int?) {
        switch rawValue {
        case 0:
            self = .doNotKeep
        case 1:
            self = .keepDraft
        case 2:
            self = .keepSent
        case 3:
            self = .keepBoth
        default:
            self = .doNotKeep
        }
    }

    var keepDraft: Bool {
        switch self {
        case .keepDraft, .keepBoth:
            return true
        default:
            return false
        }
    }

    var keepSent: Bool {
        switch self {
        case .keepSent, .keepBoth:
            return true
        default:
            return false
        }
    }
}
