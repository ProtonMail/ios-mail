// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import ProtonCore_Networking

struct ApplyLabelToMessagesRequest: Request {
    var labelID: String
    var messages: [String]

    init(labelID: String, messages: [String]) {
        self.labelID = labelID
        self.messages = messages
    }

    var parameters: [String: Any]? {
        var out = [String: Any]()
        out["LabelID"] = labelID
        out["IDs"] = messages
        return out
    }

    var method: HTTPMethod {
        return .put
    }

    var path: String {
        return MessageAPI.path + "/label"
    }
}

struct ApplyLabelToMessagesResponse: Codable {
    let code: Int
    let undoTokenData: UndoTokenData?

    enum CodingKeys: String, CodingKey {
        case code = "code"
        case undoTokenData = "undoToken"
    }
}
