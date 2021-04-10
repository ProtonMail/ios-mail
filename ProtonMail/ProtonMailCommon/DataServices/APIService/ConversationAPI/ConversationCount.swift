//
//  ConversationCount.swift
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
//

import Foundation
import PMCommon

/// Get Grouped Conversation Count
class ConversationCountRequest: Request {
    /// specific address to filter
    private let addressID: String?

    init(addressID: String?) {
        self.addressID = addressID
    }

    var path: String {
        if let addrID = addressID {
            return ConversationsAPI.path + "/count" + "?AddressID=\(addrID)"
        }
        return ConversationsAPI.path + "/count"
    }
}

class ConversationCountResponse: Response {
    var responseDict: [String: Any]?
    var counts: [ConversationCountData]?

    override func ParseResponse(_ response: [String: Any]!) -> Bool {
        responseDict = response

        guard let data = try? JSONSerialization.data(withJSONObject: response["Counts"] as Any, options: .prettyPrinted) else {
            return false
        }

        guard let result = try? JSONDecoder().decode([ConversationCountData].self, from: data) else {
            return false
        }
        counts = result
        return true
    }
}

struct ConversationCountData: Decodable {
    let labelID: String
    let total: Int
    let unread: Int

    enum CodingKeys: String, CodingKey {
        case labelID = "LabelID"
        case total = "Total"
        case unread = "Unread"
    }
}
