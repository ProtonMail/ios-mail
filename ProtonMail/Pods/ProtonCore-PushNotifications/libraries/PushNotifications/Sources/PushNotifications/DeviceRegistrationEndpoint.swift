//
//  Created on 19/7/23.
//
//  Copyright (c) 2023 Proton AG
//
//  ProtonVPN is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonVPN is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonVPN.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCoreNetworking

public final class DeviceRegistrationEndpoint: Request {
    public let path = "/core/v4/devices"

    public let method: HTTPMethod = .post

    public let parameters: [String: Any]?

    public let isAuth = true

    init(deviceToken: String, publicKey: String) {
        parameters = [
            "DeviceToken": deviceToken,
            "Environment": 6, // App Store, also for development and staging environments
            "PublicKey": publicKey
        ]
    }
}
