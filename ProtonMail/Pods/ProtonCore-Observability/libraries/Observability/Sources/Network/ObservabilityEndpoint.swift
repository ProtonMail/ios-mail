//
//  ObservabilityEndpoint.swift
//  ProtonCore-Observability - Created on 26.01.23.
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

import Foundation
import ProtonCoreNetworking

struct ObservabilityEndpoint: Request {
    var path: String { "/data/v1/metrics" }
    var method: HTTPMethod { .post }
    var headers: [String: Any]? { ["x-msg-priority": 6] }
    var isAuth: Bool { false }
    var authCredential: AuthCredential? { nil }
    var retryPolicy: ProtonRetryPolicy.RetryMode { .background }
    var nonDefaultTimeout: TimeInterval? { nil }
    var authRetry: Bool { true }
}
