//
//  ConversationLabel.swift
//  Proton Mail
//
//
//  Copyright (c) 2020 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.
//

import Foundation
import ProtonCoreNetworking

/// Label/move an array of conversations
///
class ConversationLabelRequest: ConversationLabelActionBatchableRequest {
    static let maxNumberOfConversations = 50

    private let conversationIDs: [String]
    private let labelID: String

    required init(conversationIDs: [String], labelID: String) {
        self.conversationIDs = conversationIDs
        self.labelID = labelID
    }

    var path: String {
        return ConversationsAPI.path + "/label"
    }

    var method: HTTPMethod {
        return .put
    }

    var parameters: [String: Any]? {
        let out: [String: Any] = ["IDs": conversationIDs, "LabelID": labelID]
        return out
    }
}

class ConversationLabelResponse: Response, UndoTokenResponseProtocol {
    var undoTokenData: UndoTokenData?

    override func ParseResponse(_ response: [String: Any]) -> Bool {
        guard let jsonObject = response["Responses"],
              let data = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted) else {
            return false
        }

        guard (try? JSONDecoder().decode([GeneralConversationActionResult].self, from: data)) != nil else {
            return false
        }

        parseUndoToken(response: response)

        return true
    }
}
