//
//  PaymentLaunchBillingTotalEvent.swift
//  ProtonCore-Observability - Created on 17.07.2023.
//
//  Copyright (c) 2023 Proton AG
//
//  This file is part of ProtonCore.
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

public enum PaymentsScreenViewScreenID: String, Encodable, CaseIterable {
    case planSelection
    case aiapBilling
    case dynamicPlanSelection
    case dynamicPlansUpgrade
    case dynamicPlansCurrentSubscription
}

public struct PaymentsScreenViewLabels: Encodable, Equatable {
    let screenID: PaymentsScreenViewScreenID

    enum CodingKeys: String, CodingKey {
        case screenID = "screen_id"
    }
}

extension ObservabilityEvent where Payload == PayloadWithLabels<PaymentsScreenViewLabels> {
    public static func paymentScreenView(screenID: PaymentsScreenViewScreenID) -> Self {
        ObservabilityEvent(name: "ios_core_checkout_screenView_total", labels: PaymentsScreenViewLabels(screenID: screenID))
    }
}
