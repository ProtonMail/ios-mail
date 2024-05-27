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

import ProtonCoreNetworking

struct DeviceAPI {
    static let path = "/core/v4/devices"

    /// Describes the environment in which push notifications
    /// have to be sent so the backend knows what certificate to use.
    enum APNEnvironment: Int {
        case development = 16
        case production = 6
    }
}

struct DeviceRegistrationRequest: Request {
    let deviceToken: String
    let deviceName: String
    let deviceModel: String
    let deviceVersion: String
    let appVersion: String
    let apnEnvironment: DeviceAPI.APNEnvironment
    // public key used by backend to encrypt push notifications for this user
    let publicEncryptionKey: String

    var path: String {
        DeviceAPI.path
    }

    var method: HTTPMethod {
        .post
    }

    var parameters: [String: Any]? {
        [
        "DeviceToken": deviceToken,
        "DeviceName": deviceName,
        "DeviceModel": deviceModel,
        "DeviceVersion": deviceVersion,
        "AppVersion": appVersion,
        "Environment": apnEnvironment.rawValue,
        "PublicKey": publicEncryptionKey
        ]
    }
}
