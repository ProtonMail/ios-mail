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

    var monthlyPrice: String {
        planTileData.monthlyPrice
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

    var getPlanButtonFlavor: BigButtonStyle.Flavor {
        planTileData.storeKitProductID == nil ? .weak : .regular
    }

    var billingNotice: LocalizedStringResource? {
        guard let billingPrice = planTileData.billingPrice else { return nil }

        var dateComponents = DateComponents()
        dateComponents.month = planTileData.cycleInMonths

        guard let cycleString = DateComponentsFormatter.billingCycle.string(from: dateComponents) else {
            assertionFailure()
            return nil
        }

        return L10n.billingNotice(billingPrice: billingPrice, every: cycleString)
    }

    let planTileData: PlanTileData
    private let visibleEntitlementsWhenCollapsed = 3

    private let dateComponentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    init(planTileData: PlanTileData) {
        self.planTileData = planTileData
    }

    func performWhileDisabled(action: @escaping () async -> Void) async {
        isGetButtonDisabled = true
        await action()
        isGetButtonDisabled = false
    }
}

private extension DateComponentsFormatter {
    static let billingCycle: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()
}
