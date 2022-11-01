// Copyright (c) 2021 Proton AG
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

class FeatureFlagsResponse: Response {
    var responseDict: [String: Any]?
    var result: [String: Any] = [:]

    override func ParseResponse(_ response: [String: Any]) -> Bool {
        responseDict = response

        guard let features = response["Features"] as? [[String: Any]] else {
            return false
        }

        features.forEach { dict in
            guard let type = dict["Type"] as? String,
                  let code = dict["Code"] as? String else {
                return
            }
            // Supports only boolean and integer now
            switch type {
            case "boolean":
                if let value = dict["Value"] as? Bool {
                    result[code] = value
                }
            case "integer":
                if let value = dict["Value"] as? Int {
                    result[code] = value
                }
            default:
                break
            }
        }
        return true
    }
}
