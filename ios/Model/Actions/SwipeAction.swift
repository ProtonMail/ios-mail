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

import DesignSystem
import SwiftUI

enum SwipeAction {
    case none
    case delete
    case moveToTrash
    case toggleReadStatus

    func isActionAssigned(systemFolder: SystemFolderIdentifier?) -> Bool {
        switch self {
        case .none:
            return false
        case .delete, .toggleReadStatus:
            return true
        case .moveToTrash:
            return systemFolder != .trash
        }
    }

    /// if `true` the swipe action will optimistically remove the cell from the list
    var isDestructive: Bool {
        switch self {
        case .none, .toggleReadStatus:
            return false
        case .delete, .moveToTrash:
            return true
        }
    }

    func icon(readStatus: SelectionReadStatus) -> UIImage {
        switch self {
        case .none:
            return UIImage()
        case .toggleReadStatus:
            return UIImage(resource: Action.toggleReadStatusAction(when: readStatus).icon)
        case .delete:
            return UIImage(resource: Action.deletePermanently.icon)
        case .moveToTrash:
            return UIImage(resource: Action.moveToTrash.icon)
        }
    }

    var color: Color {
        switch self {
        case .none:
            return DS.Color.Global.white
        case .toggleReadStatus:
            return DS.Color.Brand.norm
        case .delete, .moveToTrash:
            return DS.Color.Notification.error
        }
    }
}

extension SwipeAction {

    func toAction(newReadStatus: MailboxReadStatus?) -> Action? {
        switch self {
        case .toggleReadStatus:
            guard let newReadStatus else { return nil }
            return newReadStatus == .read ? .markAsRead : .markAsUnread
        case .delete:
            return .deletePermanently
        case .moveToTrash:
            return .moveToTrash
        case .none:
            return nil
        }
    }
}
