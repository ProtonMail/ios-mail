//
//  ConversationExpire.swift
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
import PMCommon

/// Control expiration time for every message in the given conversations.
///
/// Unset the expiration time by giving null to ExpirationTime. Set an absolute timestamp by providing a timestamp in ExpirationTime. Set a relative offset by using ExpiresIn.
///
/// Minimum expiration time is 15 minutes from now.
///
/// Note that a maximum of 50 conversation IDs can be passed by request.
class ConversationExpireRequest: Request {
    /// max for 50 ids
    private let conversationIDs: [String]
    /// An expiration timestamp. Null can be provided to unexpire the message.
    private let expirationTime: Int?
    /// An expiration offset. Overwrite ExpirationTime
    private let expiresIn: Int?

    init(conversationIDs: [String], expirationTime: Int?, expiresIn: Int?) {
        self.conversationIDs = conversationIDs
        self.expirationTime = expirationTime
        self.expiresIn = expiresIn
    }

    var path: String {
        return ConversationsAPI.path + "/expire"
    }

    var method: HTTPMethod {
        return .put
    }

    var parameters: [String: Any]? {
        let out: [String: Any] = [
            "IDs": conversationIDs,
            "ExpirationTime": expirationTime ?? NSNull(),
            "ExpiresIn": expiresIn ?? NSNull(),
        ]
        return out
    }
}

class ConversationExpireResponse: Response {
    var responseDict: [String: Any]?
    var results: [ConversationExpireData]?

    override func ParseResponse(_ response: [String: Any]!) -> Bool {
        responseDict = response

        guard let data = try? JSONSerialization.data(withJSONObject: response["Responses"] as Any, options: .prettyPrinted) else {
            return false
        }

        guard let result = try? JSONDecoder().decode([ConversationExpireData].self, from: data) else {
            return false
        }
        results = result
        return true
    }
}

struct ConversationExpireData: Decodable {
    let id: String
    let response: ResponseCode

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case response = "Response"
    }

    struct ResponseCode: Decodable {
        let code: Int

        enum CodingKeys: String, CodingKey {
            case code = "Code"
        }
    }
}
