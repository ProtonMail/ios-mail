//
//  PlanSelectionCheckoutTotalEvent.swift
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

public enum PlanName: String, Encodable, CaseIterable {
    case paid
    case free
}

public enum PlanSelectionCheckoutStatus: String, Encodable, CaseIterable {
    case successful
    case failed
    case processingInProgress
    case apiMightBeBlocked
    case canceled
}

public struct PlanSelectionCheckoutLabels: Encodable, Equatable {
    let status: PlanSelectionCheckoutStatus
    let plan: PlanName
}

extension ObservabilityEvent where Payload == PayloadWithLabels<PlanSelectionCheckoutLabels> {
    private enum Constants {
        static let staticEventName = "ios_core_plan_selection_checkout_total"
        static let dynamicEventName = "ios_core_dynamicPlan_selection_checkout_total"
    }

    public static func planSelectionCheckoutTotal(status: PlanSelectionCheckoutStatus, plan: PlanName, isDynamic: Bool = false) -> Self {
        isDynamic 
        ? .init(name: Constants.dynamicEventName , labels: .init(status: status, plan: plan), version: .v1)
        : .init(name: Constants.staticEventName, labels: .init(status: status, plan: plan), version: .v2)
    }
}
