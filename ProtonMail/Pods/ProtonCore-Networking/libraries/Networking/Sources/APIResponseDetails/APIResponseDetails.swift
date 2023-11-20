//
//  APIResponseDetails.swift
//  ProtonCore-Networking - Created on 20.04.23.
//
//  Copyright (c) 2023 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

public enum APIResponseDetails {
    case humanVerification(HumanVerificationDetails)
    case deviceVerification(DeviceVerificationDetails)
    case missingScopes(MissingScopesDetails)
    case empty

    var serializedDetails: [String: Any] {
        switch self {
        case .humanVerification(let humanVerificationDetails):
            return humanVerificationDetails.serialized
        case .deviceVerification(let deviceVerificationDetails):
            return deviceVerificationDetails.serialized
        case .missingScopes(let missingScopesDetails):
            return missingScopesDetails.serialized
        case .empty:
            return [:]
        }
    }
}
