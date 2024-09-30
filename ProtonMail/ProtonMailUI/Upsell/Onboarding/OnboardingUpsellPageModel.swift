// Copyright (c) 2024 Proton Technologies AG
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

import Combine

public final class OnboardingUpsellPageModel: ObservableObject {
    public enum Cycle {
        case monthly
        case annual

        var lengthInMonths: Int {
            switch self {
            case .monthly:
                return 1
            case .annual:
                return 12
            }
        }
    }

    let tiles: [OnboardingUpsellPageModel.TileModel]

    @Published public var isBusy = false
    @Published var selectedCycle: Cycle
    @Published var selectedPlanIndex: Int

    var maxDiscountForSelectedPlan: Int? {
        tiles[selectedPlanIndex].maxDiscount
    }

    var actualChargeDisclaimer: String? {
        guard let billingPrice = tiles[selectedPlanIndex].billingPricesPerCycle[selectedCycle.lengthInMonths] else {
            return nil
        }

        var dateComponents = DateComponents()
        dateComponents.setValue(selectedCycle.lengthInMonths, for: .month)

        guard let intervalDescription = dateComponentsFormatter.string(from: dateComponents) else {
            assertionFailure()
            return nil
        }

        return String(format: L10n.Upsell.billedAtEvery, billingPrice, intervalDescription)
    }

    var selectedPlanIdentifier: String? {
        tiles[selectedPlanIndex].storeKitProductIDsPerCycle[selectedCycle.lengthInMonths]
    }

    var ctaButtonTitle: String {
        String(format: L10n.Upsell.getPlan, selectedPlanName)
    }

    var getFreePlanButtonTitle: String {
        String(format: L10n.Upsell.getPlan, freePlanName)
    }

    var showGetProtonFreeButton: Bool {
        !isFreePlanSelected
    }

    private var selectedPlanName: String {
        tiles[selectedPlanIndex].planName
    }

    private var isFreePlanSelected: Bool {
        selectedPlanIndex == tiles.indices.last
    }

    private var freePlanName: String {
        tiles.last?.planName ?? "Proton Free"
    }

    private let dateComponentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    public init(tiles: [OnboardingUpsellPageModel.TileModel]) {
        self.tiles = tiles

        selectedCycle = .monthly
        selectedPlanIndex = 0
    }
}
