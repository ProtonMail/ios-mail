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
import ProtonCoreEventsLoop

struct EventAPIResponse: Decodable, EventPage {
    let eventID: String
    let refresh, more: Int
    let notices: [String]

    let userSettings: UserSettingsResponse?
    let mailSettings: NewMailSettingsResponse?
    let usedSpace: Int?
    let incomingDefaults: [IncomingDefaultResponse]?
    let user: UserResponse?
    let addresses: [AddressResponse]?
    let messageCounts: [CountData]?
    let conversationCounts: [CountData]?
    let labels: [LabelResponse]?
    let contacts: [ContactResponse]?
    let contactEmails: [NewContactEmailsResponse]?
    let conversations: [ConversationResponse]?
    let messages: [MessageResponse]?

    private enum CodingKeys: String, CodingKey {
        case eventID = "EventID"
        case refresh = "Refresh"
        case more = "More"
        case userSettings = "UserSettings"
        case mailSettings = "MailSettings"
        case usedSpace = "UsedSpace"
        case incomingDefaults = "IncomingDefaults"
        case user = "User"
        case addresses = "Addresses"
        case messageCounts = "MessageCounts"
        case conversationCounts = "ConversationCounts"
        case labels = "Labels"
        case contacts = "Contacts"
        case contactEmails = "ContactEmails"
        case conversations = "Conversations"
        case messages = "Messages"
        case notices = "Notices"
    }
}
