//
//  ChangePasswordUpdateUserKeysPasswordTotalEvent.swift
//  ProtonCore-Observability - Created on 19.03.2024.
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

import ProtonCoreNetworking

public struct ChangePasswordUpdateMailboxPasswordTotalLabels: Encodable, Equatable {
    let status: PasswordChangeHTTPResponseCodeStatus
    let twoFactorMode: TwoFactorMode

    enum CodingKeys: String, CodingKey {
        case status
        case twoFactorMode
    }
}

extension ObservabilityEvent where Payload == PayloadWithLabels<ChangePasswordUpdateMailboxPasswordTotalLabels> {
    public static func updateMailboxPassword(status: PasswordChangeHTTPResponseCodeStatus, 
                                             twoFactorMode: TwoFactorMode) -> Self {
        .init(name: "ios_core_changePassword_updateMailboxPassword_total",
              labels: .init(status: status,
                            twoFactorMode: twoFactorMode),
              version: .v2)
    }
}
