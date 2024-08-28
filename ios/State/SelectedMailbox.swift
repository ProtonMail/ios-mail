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

import UIKit

enum SelectedMailbox: Equatable {
    case inbox
    case label(labelId: ID, name: LocalizedStringResource, systemFolder: SystemFolderLabel?)

    var isInbox: Bool {
        switch self {
        case .inbox:
            return true
        case .label:
            return false
        }
    }

    var localId: ID {
        switch self {
        case .inbox:
            return .init(value: UInt64.max)
        case .label(let labelId, _, _):
            return labelId
        }
    }

    var name: LocalizedStringResource {
        switch self {
        case .inbox:
            return SystemFolderLabel.inbox.humanReadable
        case .label(_, let name, _):
            return name
        }
    }

    /// Only available for system folders mailboxes
    var systemFolder: SystemFolderLabel? {
        switch self {
        case .inbox:
            return SystemFolderLabel.inbox
        case .label(_, _, let systemFolder):
            return systemFolder
        }
    }

    static func == (lhs: SelectedMailbox, rhs: SelectedMailbox) -> Bool {
        lhs.localId == rhs.localId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(localId)
        hasher.combine(name.string)
    }
}
