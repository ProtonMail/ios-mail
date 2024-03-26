//
//  ObservabilityEnv.swift
//  ProtonCore-Observability - Created on 08.02.23.
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

import ProtonCoreNetworking

public struct ObservabilityEnv {

    public static var current = ObservabilityEnv()

    public static func report<Labels: Encodable & Equatable>(_ event: ObservabilityEvent<PayloadWithLabels<Labels>>) {
        ObservabilityEnv.current.observabilityService?.report(event)
    }

    /// The setupWorld function sets up the service used to report events before the
    /// user is logged in. Session ID is not relevant in the context of Observability.
    /// - Parameters:
    ///     - requestPerformer: Should be an instance conforming to RequestPerforming used
    ///     before the user is logged in.
    public mutating func setupWorld(requestPerformer: RequestPerforming) {
        self.observabilityService = ObservabilityServiceImpl(requestPerformer: requestPerformer)
    }

    var observabilityService: ObservabilityService?
}
