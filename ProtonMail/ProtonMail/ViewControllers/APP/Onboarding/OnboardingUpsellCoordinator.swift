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
import ProtonCorePayments
import ProtonCoreUIFoundations
import ProtonMailUI
import SwiftUI

@MainActor
final class OnboardingUpsellCoordinator {
    typealias Dependencies = HasOnboardingUpsellPageFactory
    & HasPlanService
    & HasPurchasePlan
    & HasUpsellOfferProvider
    & HasUpsellTelemetryReporter
    & HasUserManager

    typealias OnDismissCallback = @MainActor () -> Void

    private let dependencies: Dependencies
    private weak var rootViewController: UIViewController?
    private var cancellables: Set<AnyCancellable> = []

    private var availablePlansHaveBeenFetched: AnyPublisher<Void, Never> {
        dependencies.upsellOfferProvider.availablePlanPublisher
            .first(where: { $0 != nil })
            .map { _ in }
            .eraseToAnyPublisher()
    }

    private var plansDataSource: PlansDataSourceProtocol? {
        switch dependencies.planService {
        case .left:
            return nil
        case .right(let pdsp):
            return pdsp
        }
    }

    init(dependencies: Dependencies, rootViewController: UIViewController) {
        self.dependencies = dependencies
        self.rootViewController = rootViewController
    }

    func start(onDismiss: @escaping OnDismissCallback) {
        availablePlansHaveBeenFetched
            .compactMap { [unowned self] in plansDataSource?.availablePlans }
            .sink { [weak self] availablePlans in
                Task { [weak self] in
                    await self?.presentUpsellPage(availablePlans: availablePlans, onDismiss: onDismiss)
                }
            }
            .store(in: &cancellables)
    }

    private func presentUpsellPage(availablePlans: AvailablePlans, onDismiss: @escaping OnDismissCallback) async {
        dependencies.upsellTelemetryReporter.prepare(entryPoint: .postOnboarding, upsellPageVariant: .plain)

        let model = dependencies.onboardingUpsellPageFactory.makeOnboardingUpsellPageModel(for: availablePlans.plans)

        let onboardingUpsellPage = OnboardingUpsellPage(model: model) { [weak self] selectedProductId in
            self?.purchasePlan(storeKitProductId: selectedProductId, onboardingUpsellPageModel: model)
        }

        let hosting = SheetLikeSpotlightViewController(rootView: onboardingUpsellPage)
        hosting.overrideUserInterfaceStyle = .light
        hosting.onDismiss = onDismiss
        rootViewController?.present(hosting, animated: true)

        await dependencies.upsellTelemetryReporter.upsellPageDisplayed()
    }

    private func purchasePlan(storeKitProductId: String, onboardingUpsellPageModel: OnboardingUpsellPageModel) {
        rootViewController?.lockUI()
        onboardingUpsellPageModel.isBusy = true

        Task {
            let result = await dependencies.purchasePlan.execute(storeKitProductId: storeKitProductId)

            switch result {
            case .planPurchased:
                await dependencies.user.fetchUserInfo()
            case .error, .cancelled:
                break
            }

            onboardingUpsellPageModel.isBusy = false
            rootViewController?.unlockUI()

            switch result {
            case .planPurchased:
                await rootViewController?.presentedViewController?.dismiss(animated: true)
            case .error(let error):
                showErrorMessage(error as NSError)
            case .cancelled:
                break
            }
        }
    }

    private func showErrorMessage(_ error: NSError) {
        guard
            UIApplication.shared.applicationState == .active,
            let presentedViewController = rootViewController?.presentedViewController
        else {
            return
        }

        let banner = PMBanner(
            message: error.localizedDescription,
            style: PMBannerNewStyle.error,
            dismissDuration: .infinity,
            bannerHandler: PMBanner.dismiss
        )

        banner.show(at: .top, on: presentedViewController)
    }
}
