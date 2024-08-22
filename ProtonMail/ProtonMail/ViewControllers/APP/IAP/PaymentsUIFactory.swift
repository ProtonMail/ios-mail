// Copyright (c) 2023 Proton Technologies AG
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

import ProtonCorePaymentsUI
import UIKit

final class PaymentsUIFactory {
    typealias Dependencies = OnboardingUpsellCoordinator.Dependencies & UpsellCoordinator.Dependencies & HasPayments

    private unowned let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func makeView() -> PaymentsUI {
        PaymentsUI(
            payments: dependencies.payments,
            clientApp: .mail,
            shownPlanNames: Constants.shownPlanNames,
            customization: .empty
        )
    }

    @MainActor
    func makeUpsellCoordinator(rootViewController: UIViewController) -> UpsellCoordinator {
        .init(dependencies: dependencies, rootViewController: rootViewController)
    }

    @MainActor
    func makeOnboardingUpsellCoordinator(rootViewController: UIViewController) -> OnboardingUpsellCoordinator {
        .init(dependencies: dependencies, rootViewController: rootViewController)
    }
}
