// Copyright (c) 2022 Proton Technologies AG
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

// Actions that can be done on a push notification from the Notification Center.
enum PushNotificationAction: String, Codable {
    case markAsRead = "MARK_AS_READ_ACTION"
    case archive = "ARCHIVE_ACTION"
    case moveToTrash = "MOVE_TO_TRASH_ACTION"

    var title: String {
        switch self {
        case .markAsRead:
            return LocalString._title_notification_action_mark_as_read
        case .archive:
            return LocalString._title_notification_action_archive
        case .moveToTrash:
            return LocalString._title_notification_action_move_to_trash
        }
    }
}
