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

struct FeatureFlagsRequest: Request {
    private(set) var keysToFetch: [FeatureFlagKey] = []

    var path: String {
        "/core/v4/features"
    }

    var method: HTTPMethod {
        .get
    }

    init(keys: [FeatureFlagKey]? = nil) {
        if let keys = keys, !keys.isEmpty {
            keysToFetch = keys
        } else {
            keysToFetch = FeatureFlagKey.allCases
        }
    }

    var parameters: [String: Any]? {
        guard !keysToFetch.isEmpty else {
            return nil
        }
        var result: [String: Any] = [:]
        let queryString = keysToFetch
            .map { $0.rawValue }
            .joined(separator: ",")
        // Code=XXX,XXX
        result["Code"] = queryString
        return result
    }
}
