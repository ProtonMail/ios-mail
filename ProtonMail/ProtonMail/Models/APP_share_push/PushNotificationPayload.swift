// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation

/// This model is for both local and remote notifications' payload. The intention is accessing to the userInfo dictionary
/// in one single place and also to have a little of a self documented payload. Most attributes are optional for legacy
/// implementation reasons.
struct PushNotificationPayload: Decodable {
    let viewMode: Int?
    let action: String?
    /// In remote notifications, the `uid` value corresponds to the sessionId and the app uses it to retrieve the userId
    let uid: String?
    let unreadMessages: Int?
    let unreadConversations: Int?
    let encryptedMessage: String?

    // Attributes used by local notifications
    let localNotification: Bool?
    let category: String?
    let messageId: String?

    var isLocalNotification: Bool {
        localNotification ?? false
    }

    private enum CodingKeys : String, CodingKey {
        case viewMode
        case action
        case uid = "UID"
        case unreadMessages
        case unreadConversations
        case encryptedMessage
        case localNotification
        case category
        case messageId = "message_id"
    }

    init(userInfo: [AnyHashable : Any]) throws {
        let data = try JSONSerialization.data(withJSONObject: userInfo, options: .prettyPrinted)
        self = try JSONDecoder().decode(PushNotificationPayload.self, from: data)
    }
}
