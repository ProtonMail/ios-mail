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

import UserNotifications
import proton_app_uniffi

enum NotificationQuickAction: String, CaseIterable {
    case markAsRead
    case moveToArchive
    case moveToTrash

    static let applePushNotificationServiceCategory = "message_created"

    private var title: LocalizedStringResource {
        switch self {
        case .markAsRead: Action.markAsRead.name
        case .moveToArchive: Action.moveToArchive.name
        case .moveToTrash: Action.moveToTrash.name
        }
    }

    private var options: UNNotificationActionOptions {
        self == .moveToTrash ? .destructive : []
    }

    func registrableAction() -> UNNotificationAction {
        .init(identifier: rawValue, title: title.string, options: options)
    }

    func executableAction(remoteId: RemoteId) -> PushNotificationQuickAction {
        switch self {
        case .markAsRead: .markAsRead(remoteId: remoteId)
        case .moveToArchive: .moveToArchive(remoteId: remoteId)
        case .moveToTrash: .moveToTrash(remoteId: remoteId)
        }
    }
}
