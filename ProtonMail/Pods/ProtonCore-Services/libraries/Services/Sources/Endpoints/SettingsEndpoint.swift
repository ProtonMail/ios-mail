//
//  SettingsEndpoint.swift
//  ProtonCore-Service - Created on 02/05/2024.
//
//  Copyright (c) 2024 Proton Technologies AG
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCoreNetworking

public class SettingsResponse: APIDecodableResponse {
    public let code: Int
    public let userSettings: UserSettings
}

public struct UserSettings: Codable {
    public let _2FA: TwoFA

    public struct TwoFA: Codable {
        public var enabled: EnabledMechanism
        public let registeredKeys: [RegisteredKey]

        public init(enabled: EnabledMechanism, registeredKeys: [RegisteredKey]) {
            self.enabled = enabled
            self.registeredKeys = registeredKeys
        }
    }
}

public final class SettingsEndpoint: Request {

    public var path: String {
        "/core/v4/settings"
    }

    public init() { }
}
