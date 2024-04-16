//
//  PushNotificationsReceivedTotalEvent.swift
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

public struct PushNotificationsReceivedTotalLabels: Encodable, Equatable {
    let result: PushNotificationsReceivedResult
    let applicationStatus: ApplicationStatus

    enum CodingKeys: String, CodingKey {
        case result
        case applicationStatus = "application_status"
    }
}

extension ObservabilityEvent where Payload == PayloadWithLabels<PushNotificationsReceivedTotalLabels> {
    public static func pushNotificationsReceived(result: PushNotificationsReceivedResult,
                                                 applicationStatus: ApplicationStatus) -> Self {
        .init(name: "ios_core_pushNotifications_received_total", 
              labels: .init(result: result, applicationStatus: applicationStatus))
    }
}
