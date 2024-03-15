//
//  AccountRecoveryScreenView.swift
//  ProtonCore-Observability - Created on 29.08.2023.
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

public enum AccountRecoveryScreenViewScreenID: String, Encodable, CaseIterable {
    case gracePeriodInfo
    case cancelResetPassword
    case passwordChangeInfo
    case recoveryCancelledInfo
    case recoveryExpiredInfo
}

public struct AccountRecoveryScreenViewLabels: Encodable, Equatable {
    let screenID: AccountRecoveryScreenViewScreenID

    enum CodingKeys: String, CodingKey {
        case screenID = "screen_id"
    }
}

extension ObservabilityEvent where Payload == PayloadWithLabels<AccountRecoveryScreenViewLabels> {
    public static func accountRecoveryScreenView(screenID: AccountRecoveryScreenViewScreenID) -> Self {
        ObservabilityEvent(name: "ios_core_accountRecovery_screenView_total", labels: AccountRecoveryScreenViewLabels(screenID: screenID))
    }
}
