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
import proton_app_uniffi

enum SelectedMailbox: Equatable {
    /// The `inbox` case is a workaround to be able to launch the mailbox screen without having to wait
    /// until the SDK returns the list of available local label ids.
    case inbox
    case systemFolder(labelId: ID, systemFolder: SystemLabel)
    case customLabel(labelId: ID, name: LocalizedStringResource)
    case customFolder(labelId: ID, name: LocalizedStringResource)

    var isInbox: Bool {
        switch self {
        case .inbox:
            return true
        case .systemFolder, .customLabel, .customFolder:
            return false
        }
    }

    var isCustomLabel: Bool {
        switch self {
        case .customLabel:
            return true
        case .inbox, .systemFolder, .customFolder:
            return false
        }
    }

    var localId: ID {
        switch self {
        case .inbox:
            return .init(value: UInt64.max)
        case .systemFolder(let labelId, _):
            return labelId
        case .customLabel(let labelId, _):
            return labelId
        case .customFolder(let labelId, _):
            return labelId
        }
    }

    var name: LocalizedStringResource {
        switch self {
        case .inbox:
            return SystemLabel.inbox.humanReadable
        case .systemFolder(_, let systemFolder):
            return systemFolder.humanReadable
        case .customLabel(_, let name):
            return name
        case .customFolder(_, let name):
            return name
        }
    }

    /// Only available for system folders mailboxes
    var systemFolder: SystemLabel? {
        switch self {
        case .inbox:
            return SystemLabel.inbox
        case .systemFolder(_, let systemFolder):
            return systemFolder
        case .customLabel, .customFolder:
            return nil
        }
    }

    static func == (lhs: SelectedMailbox, rhs: SelectedMailbox) -> Bool {
        lhs.localId == rhs.localId
    }
}
