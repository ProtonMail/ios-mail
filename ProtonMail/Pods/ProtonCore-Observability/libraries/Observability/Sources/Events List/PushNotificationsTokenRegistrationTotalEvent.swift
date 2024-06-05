//
//  PushNotificationsTokenRegistrationTotalEvent.swift
//  ProtonCore-Observability - Created on 07.03.24.
//
//  Copyright (c) 2022 Proton Technologies AG
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

import ProtonCoreNetworking

public struct PushNotificationsTokenRegistrationTotalLabels: Encodable, Equatable {
    let status: PushNotificationsHTTPResponseCodeStatus

    enum CodingKeys: String, CodingKey {
        case status
    }
}

extension ObservabilityEvent where Payload == PayloadWithLabels<PushNotificationsTokenRegistrationTotalLabels> {
    public static func pushNotificationsTokenRegistered(status: PushNotificationsHTTPResponseCodeStatus) -> Self {
        .init(name: "ios_core_pushNotifications_token_registration_total", labels: .init(status: status))
    }
}

