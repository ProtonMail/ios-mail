//
// Copyright (c) 2025 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import InboxCoreUI
import Foundation
import PaymentsNG
import StoreKit

@MainActor
@Observable
final class PlanTileModel: Identifiable {
    var areEntitlementsExpanded = false
    private(set) var isGetButtonDisabled = false

    var storeKitProductID: String? {
        planTileData.storeKitProductID
    }

    var planName: String {
        planTileData.planName
    }

    var isBestValue: Bool {
        planTileData.planName.contains("Unlimited")
    }

    var cycleInMonths: Int {
        planTileData.cycleInMonths
    }

    var formattedPrice: String {
        planTileData.formattedPrice
    }

    var localizedCycleUnit: String {
        let subscriptionPeriodUnit = Product.SubscriptionPeriod.Unit(cycleInMonths: cycleInMonths) ?? .month
        return subscriptionPeriodUnit.localizedDescription
    }

    var discount: PlanTileData.Discount? {
        planTileData.discount
    }

    var entitlements: [DescriptionEntitlement] {
        areEntitlementsExpanded ? planTileData.entitlements : Array(planTileData.entitlements.prefix(visibleEntitlementsWhenCollapsed))
    }

    var isExpandingButtonVisible: Bool {
        planTileData.entitlements.count > visibleEntitlementsWhenCollapsed
    }

    var getPlanButtonTitle: LocalizedStringResource {
        isFree ? L10n.continueWithFreePlan : L10n.getPlan(named: planTileData.planName)
    }

    var getPlanButtonFlavor: BigButtonStyle.Flavor {
        isFree ? .weak : .regular
    }

    let planTileData: PlanTileData
    private let visibleEntitlementsWhenCollapsed = 3

    private var isFree: Bool {
        planTileData.storeKitProductID == nil
    }

    init(planTileData: PlanTileData) {
        self.planTileData = planTileData
    }

    func performWhileDisabled(action: @escaping () async -> Void) async {
        isGetButtonDisabled = true
        await action()
        isGetButtonDisabled = false
    }
}

private extension Product.SubscriptionPeriod.Unit {
    init?(cycleInMonths: Int) {
        switch cycleInMonths {
        case 1:
            self = .month
        case 12:
            self = .year
        default:
            return nil
        }
    }
}
