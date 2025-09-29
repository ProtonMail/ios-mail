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

import proton_app_uniffi

enum RemoteNotificationType {
    case newMessage(sessionId: String, remoteId: RemoteId)
    case urlToOpen(String)

    init?(userInfo: [AnyHashable: Any]) {
        if let sessionId = userInfo["UID"] as? String, let messageId = userInfo["messageId"] as? String {
            self = .newMessage(sessionId: sessionId, remoteId: .init(value: messageId))
        } else if let url = userInfo["url"] as? String {
            self = .urlToOpen(url)
        } else {
            return nil
        }
    }
}
