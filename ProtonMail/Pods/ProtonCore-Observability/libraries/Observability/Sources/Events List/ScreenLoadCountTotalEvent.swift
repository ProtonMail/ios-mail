//
//  ScreenLoadCountTotalEvent.swift
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

public enum ScreenName: String, Encodable, CaseIterable {
    case externalAccountAvailable = "external_account_available"
    case protonAccountAvailable = "proton_account_available"
    case passwordCreation = "password_creation"
    case setRecoveryMethod = "set_recovery_method"
    case emailVerification = "email_verification"
    case congratulation = "congratulation"
    case createProtonAccountWithCurrentEmail = "create_proton_account_with_current_email"
    case planSelection = "plan_selection"
}

public struct ScreenLoadCountLabels: Encodable, Equatable {
    let screenName: ScreenName

    enum CodingKeys: String, CodingKey {
        case screenName = "screen_name"
    }
}

extension ObservabilityEvent where Payload == PayloadWithLabels<ScreenLoadCountLabels> {
    public static func screenLoadCountTotal(screenName: ScreenName) -> Self {
        .init(name: "ios_core_screen_load_count_total", labels: .init(screenName: screenName))
    }
}
