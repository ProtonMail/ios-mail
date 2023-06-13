//
//  APIService+DeviceExtension.swift
//  Proton Mail
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import GoLibs
import ProtonCore_Networking
import ProtonCore_Services

extension PMAPIService {

    func deviceUnregister(_ settings: PushSubscriptionSettings, completion: @escaping JSONCompletion) {
        guard !userCachedStatus.isForcedLogout else {
            return
        }

        let parameters = [
            "DeviceToken": settings.token,
            "UID": settings.UID
        ]
        request(method: .delete,
                path: DeviceAPI.path,
                parameters: parameters,
                headers: .empty,
                authenticated: false,
                autoRetry: false,
                customAuthCredential: nil,
                nonDefaultTimeout: nil,
                retryPolicy: .userInitiated,
                jsonCompletion: completion)
    }
}
