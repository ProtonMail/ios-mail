//
//  TelemetryRequest.swift
//  ProtonCore-Telemetry - Created on 26.02.2024.
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

final class TelemetryRequest: Request {

    private let event: any TelemetryEventProtocol

    init(event: any TelemetryEventProtocol) {
        self.event = event
    }

    var path: String {
        "/data/v1/stats"
    }

    var method: HTTPMethod = .post

    var isAuth: Bool {
        return true
    }

    var parameters: [String: Any]? {
        [
            "MeasurementGroup": event.measurementGroup,
            "Event": event.event,
            "Values": event.values,
            "Dimensions": event.dimensions
        ]
    }
}
