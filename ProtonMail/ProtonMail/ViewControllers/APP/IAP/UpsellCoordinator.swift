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

    typealias OnDismissCallback = @MainActor () -> Void

    private let dependencies: Dependencies
    private weak var rootViewController: UIViewController?
    private var paymentsUI: PaymentsUI?

    private let paymentsUnavailableMessage = "Payments are disabled in TestFlight builds using production environment"

    init(dependencies: Dependencies, rootViewController: UIViewController) {
        self.dependencies = dependencies
        self.rootViewController = rootViewController
    }

    func start(entryPoint: UpsellPageEntryPoint, onDismiss: OnDismissCallback? = nil) {
        Task {
            await start(entryPoint: entryPoint, onDismiss: onDismiss)
        }
    }

    func start(entryPoint: UpsellPageEntryPoint, onDismiss: OnDismissCallback? = nil) async {
        if let availablePlan = await prepareAvailablePlan() {
            await presentUpsellPage(availablePlan: availablePlan, entryPoint: entryPoint, onDismiss: onDismiss)
        } else {
            await fallbackToPreviousFlow(entryPoint: entryPoint, onDismiss: onDismiss)
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
        entryPoint: UpsellPageEntryPoint,
        onDismiss: OnDismissCallback?
    ) async {
        let upsellPageModel = dependencies.upsellPageFactory.makeUpsellPageModel(
            for: availablePlan,
            entryPoint: entryPoint
        )

        dependencies.upsellTelemetryReporter.prepare(entryPoint: entryPoint, upsellPageVariant: upsellPageModel.variant)

        let upsellPage = UpsellPage(model: upsellPageModel, entryPoint: entryPoint) { [weak self] selectedProductId in
            self?.purchasePlan(storeKitProductId: selectedProductId, upsellPageModel: upsellPageModel)
        }

        let hostingController = SheetLikeSpotlightViewController(rootView: upsellPage)
        hostingController.modalTransitionStyle = .crossDissolve
        hostingController.onDismiss = onDismiss
        rootViewController?.present(hostingController, animated: false)

        await dependencies.upsellTelemetryReporter.upsellPageDisplayed()
    }

    private func purchasePlan(storeKitProductId: String, upsellPageModel: UpsellPageModel) {
        guard Application.arePaymentsEnabled else {
            showErrorMessage(paymentsUnavailableMessage)
            return
        }

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
        showErrorMessage(error.localizedDescription)
    }

    private func showErrorMessage(_ message: String) {
        guard
            UIApplication.shared.applicationState == .active,
            let presentedViewController = rootViewController?.presentedViewController
        else {
            return
        }

        let banner = PMBanner(
            message: message,
            style: PMBannerNewStyle.error,
            dismissDuration: .infinity,
            bannerHandler: PMBanner.dismiss
        )

        banner.show(at: .top, on: presentedViewController)
    }

    // MARK: legacy flows

    private func fallbackToPreviousFlow(entryPoint: UpsellPageEntryPoint, onDismiss: OnDismissCallback?) async {
        switch entryPoint {
        case .autoDelete:
            let presentingNavigationController: UINavigationController

            if let navigationController = rootViewController as? UINavigationController {
                presentingNavigationController = navigationController
            } else if let navigationController = rootViewController?.navigationController {
                presentingNavigationController = navigationController
            } else {
                return
            }

            let upsellSheet = AutoDeleteUpsellSheetView { [weak self] _ in
                Task { [weak self] in
                    await self?.presentCoreSubscriptionScreen(onDismiss: onDismiss)
                }
            }

            upsellSheet.present(on: presentingNavigationController.view)
        case .contactGroups:
            await presentCoreSubscriptionScreen(onDismiss: onDismiss)
        case .folders:
            presentAlertController(
                title: LocalString._creating_folder_not_allowed,
                message: LocalString._upgrade_to_create_folder
            )
        case .header:
            await presentCoreSubscriptionScreen(onDismiss: onDismiss)
        case .labels:
            presentAlertController(
                title: LocalString._creating_label_not_allowed,
                message: LocalString._upgrade_to_create_label
            )
        case .mobileSignature:
            await presentCoreSubscriptionScreen(onDismiss: onDismiss)
        case .postOnboarding:
            onDismiss?()
        case .scheduleSend:
            presentPromotionView(type: .scheduleSend, onDismiss: onDismiss)
        case .snooze:
            presentPromotionView(type: .snooze, onDismiss: onDismiss)
        }
    }

    private func presentAlertController(title: String, message: String?, okAction: ((UIAlertAction?) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addOKAction(handler: okAction)
        rootViewController?.present(alert, animated: true)
    }

    private func presentPromotionView(type: PromotionView.PromotionType, onDismiss: OnDismissCallback?) {
        guard let navigationController = rootViewController?.navigationController else {
            return
        }

        let promotionView = PromotionView()

        promotionView.presentPaymentUpgradeView = { [weak self] in
            Task { [weak self] in
                await self?.presentCoreSubscriptionScreen(onDismiss: onDismiss)
            }
        }

        promotionView.viewWasDismissed = onDismiss
        promotionView.present(on: navigationController.view, type: type)
    }

    private func presentCoreSubscriptionScreen(onDismiss: OnDismissCallback?) async {
        guard Application.arePaymentsEnabled else {
            presentAlertController(title: paymentsUnavailableMessage, message: nil) { _ in
                onDismiss?()
            }

            return
        }

        let paymentsUI = dependencies.paymentsUIFactory.makeView()

        await withCheckedContinuation { continuation in
            // this is necessary because showUpgradePlan completion handler is called several times
            let nullableContinuation: Atomic<CheckedContinuation<Void, Never>?> = .init(continuation)

            // and this is necessary because .close is being returned multiple times
            let closeAlreadyReturnedOnce: Atomic<Bool> = .init(false)

            paymentsUI.showUpgradePlan(presentationType: .modal, backendFetch: true) { resultReason in
                nullableContinuation.mutate {
                    $0?.resume()
                    $0 = nil
                }

                switch resultReason {
                case .close:
                    if !closeAlreadyReturnedOnce.value {
                        closeAlreadyReturnedOnce.mutate { $0 = true }
                        onDismiss?()
                    }
                case .purchasedPlan:
                    Task {
                        await self.dependencies.user.fetchUserInfo()
                    }
                default:
                    break
                }
            }
        }

        self.paymentsUI = paymentsUI
    }
}
