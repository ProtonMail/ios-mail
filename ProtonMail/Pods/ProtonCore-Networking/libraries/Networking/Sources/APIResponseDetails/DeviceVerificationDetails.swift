//
//  DeviceVerificationDetails.swift
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

public struct DeviceVerificationDetails: Codable, Equatable {

    let type: Int
    let payload: String

    enum CodingKeys: String, CodingKey {
        case type = "challengeType"
        case payload = "challengePayload"

        // we provide the uppercase variants for when we work with JSON dictionary and not with Codable objects
        var uppercased: String {
            "\(rawValue.prefix(1).uppercased())\(rawValue.dropFirst())"
        }
    }

    var serialized: [String: Any] {
        var responseDict: [String: Any] = [:]
        responseDict[CodingKeys.type.uppercased] = type
        responseDict[CodingKeys.payload.uppercased] = payload
        return responseDict
    }
}

public struct ResponseWithDeviceVerificationDetails: Codable {
    public var details: DeviceVerificationDetails?
}
