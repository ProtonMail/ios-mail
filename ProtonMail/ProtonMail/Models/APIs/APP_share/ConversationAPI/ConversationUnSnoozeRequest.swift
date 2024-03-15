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

import ProtonCoreNetworking

struct ConversationUnSnoozeRequest: Request {
    private let conversationIDs: [ConversationID]

    init(conversationIDs: [ConversationID]) {
        self.conversationIDs = conversationIDs
    }

    var path: String {
        "\(ConversationsAPI.path)/unsnooze"
    }

    var method: HTTPMethod {
        return .put
    }

    var parameters: [String: Any]? {
        [
            "IDs": conversationIDs.map(\.rawValue)
        ]
    }
}
