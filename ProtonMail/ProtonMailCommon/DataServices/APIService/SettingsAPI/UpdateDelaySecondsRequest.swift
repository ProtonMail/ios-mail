// Copyright (c) 2022 Proton Technologies AG
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

import Foundation
import ProtonCore_DataModel
import ProtonCore_Networking

// Mark : update undo send delay seconds
final class UpdateDelaySecondsRequest: Request {
    private let delaySeconds: Int
    var path: String {
        return "\(SettingsAPI.path)/delaysend"
    }

    var method: HTTPMethod { .put }

    var parameters: [String: Any]? {
        ["DelaySendSeconds": self.delaySeconds]
    }

    init(delaySeconds: Int) {
        self.delaySeconds = delaySeconds
    }
}
