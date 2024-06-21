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

public enum PaymentLaunchBillingTotalStatus: String, Encodable, CaseIterable {
    case success
    case purchasedPlan
    case planPurchaseProcessingInProgress
    case apiBlocked
    case purchaseError
    case canceled
    case renewalNotification
    case unknown
}

public struct PaymentLaunchBillingTotalLabels: Encodable, Equatable {
    let status: PaymentLaunchBillingTotalStatus

    enum CodingKeys: String, CodingKey {
        case status
    }
}

extension ObservabilityEvent where Payload == PayloadWithLabels<PaymentLaunchBillingTotalLabels> {
    private enum Constants {
        static let staticEventName = "ios_core_checkout_aiapBilling_launchBilling_total"
        static let dynamicEventName = "ios_core_checkout_dynamicPlans_aiapBilling_launchBilling_total"
    }

    public static func paymentLaunchBillingTotal(status: PaymentLaunchBillingTotalStatus, isDynamic: Bool = false) -> Self {
        ObservabilityEvent(name: isDynamic ? Constants.dynamicEventName : Constants.staticEventName, labels: PaymentLaunchBillingTotalLabels(status: status))
    }
}
