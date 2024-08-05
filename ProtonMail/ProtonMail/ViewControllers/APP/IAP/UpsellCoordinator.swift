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

import MBProgressHUD
@preconcurrency import ProtonCorePayments
import ProtonCorePaymentsUI
import ProtonCoreUIFoundations
import ProtonCoreUtilities
import ProtonMailUI
import UIKit

@MainActor
final class UpsellCoordinator {
    typealias Dependencies = AnyObject
    & HasPaymentsUIFactory
    & HasPurchasePlan
    & HasUpsellOfferProvider
    & HasUpsellPageFactory
    & HasUpsellTelemetryReporter
    & HasUserManager

    private let dependencies: Dependencies
    private weak var rootViewController: UIViewController?
    private var paymentsUI: PaymentsUI?

    init(dependencies: Dependencies, rootViewController: UIViewController) {
        self.dependencies = dependencies
        self.rootViewController = rootViewController
    }

    func start(entryPoint: UpsellPageEntryPoint) {
        Task {
            await start(entryPoint: entryPoint)
        }
    }

    func start(entryPoint: UpsellPageEntryPoint) async {
        if let availablePlan = await prepareAvailablePlan() {
            await presentUpsellPage(availablePlan: availablePlan, entryPoint: entryPoint)
        } else {
            await fallBackToCorePaymentsUI()
        }
    }

    private func prepareAvailablePlan() async -> AvailablePlans.AvailablePlan? {
        if let availablePlan = dependencies.upsellOfferProvider.availablePlan {
            return availablePlan
        } else if let rootViewController {
            let hud = MBProgressHUD.showAdded(to: rootViewController.view, animated: true)

            do {
                try await dependencies.upsellOfferProvider.update()
            } catch {
                SystemLogger.log(error: error, category: .iap)
            }

            hud.hide(animated: true)

            return dependencies.upsellOfferProvider.availablePlan
        } else {
            return nil
        }
    }

    // MARK: modern upsell flow

    private func presentUpsellPage(
        availablePlan: AvailablePlans.AvailablePlan,
        entryPoint: UpsellPageEntryPoint
    ) async {
        dependencies.upsellTelemetryReporter.prepare()

        let upsellPageModel = dependencies.upsellPageFactory.makeUpsellPageModel(for: availablePlan)

        let upsellPage = UpsellPage(model: upsellPageModel, entryPoint: entryPoint) { [weak self] selectedProductId in
            self?.purchasePlan(storeKitProductId: selectedProductId, upsellPageModel: upsellPageModel)
        }

        let hostingController = SheetLikeSpotlightViewController(rootView: upsellPage)
        hostingController.modalTransitionStyle = .crossDissolve
        rootViewController?.present(hostingController, animated: false)

        await dependencies.upsellTelemetryReporter.upsellButtonTapped()
    }

    private func purchasePlan(storeKitProductId: String, upsellPageModel: UpsellPageModel) {
        rootViewController?.lockUI()
        upsellPageModel.isBusy = true

        Task {
            let result = await dependencies.purchasePlan.execute(storeKitProductId: storeKitProductId)

            switch result {
            case .planPurchased:
                await dependencies.user.fetchUserInfo()
            case .error, .cancelled:
                break
            }

            upsellPageModel.isBusy = false
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
        guard UIApplication.shared.applicationState == .active, let rootViewController else {
            return
        }

        let banner = PMBanner(
            message: error.localizedDescription,
            style: PMBannerNewStyle.error,
            dismissDuration: .infinity,
            bannerHandler: PMBanner.dismiss
        )

        banner.show(at: .top, on: rootViewController)
    }

    // MARK: legacy Core flow

    private func fallBackToCorePaymentsUI() async {
        let paymentsUI = dependencies.paymentsUIFactory.makeView()

        await withCheckedContinuation { continuation in
            // this is necessary because showUpgradePlan completion handler is called several times
            let nullableContinuation: Atomic<CheckedContinuation<Void, Never>?> = .init(continuation)

            paymentsUI.showUpgradePlan(presentationType: .modal, backendFetch: true) { _ in
                nullableContinuation.mutate {
                    $0?.resume()
                    $0 = nil
                }
            }
        }

        self.paymentsUI = paymentsUI
    }
}
