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
    case toggleReadStatus
    case delete

    var isActionAssigned: Bool {
        if case .none = self {
            return false
        }
        return true
    }

    /// if `true` the swipe action will optimistically remove the cell from the list
    var isDestructive: Bool {
        switch self {
        case .none, .toggleReadStatus:
            return false
        case .delete:
            return true
        }
    }

    func icon(readStatus: SelectionReadStatus) -> UIImage {
        switch self {
        case .none:
            return UIImage()
        case .toggleReadStatus:
            return Action.toggleReadStatusAction(when: readStatus).icon
        case .delete:
            return Action.delete.icon
        }
    }

    var color: Color {
        switch self {
        case .none:
            return DS.Color.Global.white
        case .toggleReadStatus:
            return DS.Color.Brand.norm
        case .delete:
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
            return .delete
        default:
            return nil
        }
    }
}
