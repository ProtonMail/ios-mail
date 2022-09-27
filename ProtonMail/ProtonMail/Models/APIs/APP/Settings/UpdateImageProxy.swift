// Copyright (c) 2022 Proton AG
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

import ProtonCore_DataModel
import ProtonCore_Networking

final class UpdateImageProxy: Request {
    enum Action: Int {
        case add = 1
        case remove = 0
    }

    let flags: ProtonCore_DataModel.ImageProxy
    let action: Action
    let authCredential: AuthCredential

    init(flags: ProtonCore_DataModel.ImageProxy, action: Action, authCredential: AuthCredential) {
        self.flags = flags
        self.action = action
        self.authCredential = authCredential
    }

    var parameters: [String: Any]? {
        [
            "Action": action.rawValue,
            "ImageProxy": flags.rawValue
        ]
    }

    var method: HTTPMethod {
        .put
    }

    var path: String {
        "\(SettingsAPI.path)/imageproxy"
    }
}
