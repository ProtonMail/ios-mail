//
//  ExternalAccountAvailableSignupTotalEvent.swift
//  ProtonCore-Observability - Created on 16.12.22.
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

public enum ExternalAccountAvailableStatus: String, Encodable, CaseIterable {
    case successful
    case failed
    case apiMightBeBlocked
    case notAvailable
}

public struct ExternalAccountAvailableLabels: Encodable, Equatable {
    let status: ExternalAccountAvailableStatus
}

extension ObservabilityEvent where Payload == PayloadWithLabels<ExternalAccountAvailableLabels> {
    public static func externalAccountAvailableSignupTotal(status: ExternalAccountAvailableStatus) -> Self {
        .init(name: "ios_core_external_account_available_signup_total", labels: .init(status: status), version: .v2)
    }
}
