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

import ProtonCore_Networking

final class UpdateNextMessageOnMoveRequest: Request {
    let isEnable: Bool

    init(isEnable: Bool) {
        self.isEnable = isEnable
    }

    var method: HTTPMethod {
        return .put
    }

    var path: String {
        return SettingsAPI.path + "/next-message-on-move"
    }

    var parameters: [String: Any]? {
        let rawValue = isEnable == true ? 1 : 0
        return ["NextMessageOnMove": rawValue]
    }
}
