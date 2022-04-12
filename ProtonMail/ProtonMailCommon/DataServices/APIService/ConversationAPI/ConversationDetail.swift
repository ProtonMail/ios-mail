//
//  ConversationDetail.swift
//  ProtonMail
//
//
//  Copyright (c) 2020 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCore_Networking

/// Get conversation and associated message metadata
class ConversationDetailsRequest: Request {
    private let conversationID: String

    /// specific message in conversation to return fully (not only metadata)
    private let messageID: String?
    init(conversationID: String, messageID: String?) {
        self.conversationID = conversationID
        self.messageID = messageID
    }

    var path: String {
        if let msgID = messageID {
            return ConversationsAPI.path + "/\(conversationID)" + "?MessageID=\(msgID)"
        }
        return ConversationsAPI.path + "/\(conversationID)"
    }
}

class ConversationDetailsResponse: Response {
    var messages: [[String: Any]]? // one full and others metadata only
    var conversation: [String: Any]?

    override func ParseResponse(_ response: [String: Any]?) -> Bool {
        guard let jsonObject = response else { return false }
        var hasResponse = false
        if let messages = jsonObject["Messages"] as? [[String: Any]] {
            self.messages = messages
            hasResponse = true
        }
        if let conversation = jsonObject["Conversation"] as? [String: Any] {
            self.conversation = conversation
            hasResponse = true
        }
        return hasResponse
    }
}
