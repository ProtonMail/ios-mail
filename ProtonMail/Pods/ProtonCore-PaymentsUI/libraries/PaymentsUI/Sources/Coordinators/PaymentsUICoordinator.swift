//
//  PaymentsUICoordinator.swift
//  ProtonCorePaymentsUI - Created on 01/06/2021.
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

#if os(iOS)

import UIKit
import enum ProtonCoreDataModel.ClientApp
import ProtonCorePayments
import ProtonCoreNetworking
import ProtonCoreUIFoundations
import ProtonCoreObservability
import ProtonCoreFoundations
import ProtonCoreUtilities
import ProtonCoreFeatureSwitch
import ProtonCoreLog

final class PaymentsUICoordinator {
    
    private var viewController: UIViewController?
    private var presentationType: PaymentsUIPresentationType = .modal
    private var mode: PaymentsUIMode = .signup
    private var completionHandler: ((PaymentsUIResultReason) -> Void)?
    var viewModel: PaymentsUIViewModel?
    private var onDohTroubleshooting: () -> Void
    
    private let planService: Either<ServicePlanDataServiceProtocol, PlansDataSourceProtocol>
    private let storeKitManager: StoreKitManagerProtocol
    private let purchaseManager: PurchaseManagerProtocol
    private let shownPlanNames: ListOfShownPlanNames
    private let customization: PaymentsUICustomizationOptions
    private let alertManager: PaymentsUIAlertManager
    private let clientApp: ClientApp
    private let storyboardName: String
    
    private var unfinishedPurchasePlan: InAppPurchasePlan? {
        didSet {
            guard let unfinishedPurchasePlan = unfinishedPurchasePlan else { return }
            viewModel?.unfinishedPurchasePlan = unfinishedPurchasePlan
        }
    }
    
    var paymentsUIViewController: PaymentsUIViewController? {
        didSet { alertManager.viewController = paymentsUIViewController }
    }
    
    init(planService: Either<ServicePlanDataServiceProtocol, PlansDataSourceProtocol>,
         storeKitManager: StoreKitManagerProtocol,
         purchaseManager: PurchaseManagerProtocol,
         clientApp: ClientApp,
         shownPlanNames: ListOfShownPlanNames,
         customization: PaymentsUICustomizationOptions,
         alertManager: PaymentsUIAlertManager,
         onDohTroubleshooting: @escaping () -> Void) {
        self.planService = planService
        self.storeKitManager = storeKitManager
        self.purchaseManager = purchaseManager
        self.shownPlanNames = shownPlanNames
        self.alertManager = alertManager
        self.clientApp = clientApp
        self.customization = customization
        self.storyboardName = "PaymentsUI"
        self.onDohTroubleshooting = onDohTroubleshooting
    }
    
    func start(viewController: UIViewController?, completionHandler: @escaping ((PaymentsUIResultReason) -> Void)) {
        self.viewController = viewController
        self.mode = .signup
        self.completionHandler = completionHandler
        if FeatureFactory.shared.isEnabled(.dynamicPlans) {
            Task {
                try await showPaymentsUI(servicePlan: planService)
            }
        } else {
            showPaymentsUI(servicePlan: planService, backendFetch: false)
        }
    }
    
    func start(presentationType: PaymentsUIPresentationType, mode: PaymentsUIMode, backendFetch: Bool, completionHandler: @escaping ((PaymentsUIResultReason) -> Void)) {
        self.presentationType = presentationType
        self.mode = mode
        self.completionHandler = completionHandler
        if FeatureFactory.shared.isEnabled(.dynamicPlans) {
            Task {
                try await showPaymentsUI(servicePlan: planService)
            }
        } else {
            showPaymentsUI(servicePlan: planService, backendFetch: backendFetch)
        }
    }
    
    // MARK: Private methods
    
    private func showPaymentsUI(servicePlan: Either<ServicePlanDataServiceProtocol, PlansDataSourceProtocol>) async throws {
        let paymentsUIViewController = await MainActor.run {
            let paymentsUIViewController = UIStoryboard.instantiate(
                PaymentsUIViewController.self, storyboardName: storyboardName, inAppTheme: customization.inAppTheme
            )
            paymentsUIViewController.delegate = self
            paymentsUIViewController.onDohTroubleshooting = { [weak self] in
                self?.onDohTroubleshooting()
            }
            return paymentsUIViewController
        }
        
        viewModel = PaymentsUIViewModel(
            mode: mode,
            storeKitManager: storeKitManager,
            planService: planService,
            shownPlanNames: shownPlanNames,
            clientApp: clientApp,
            customPlansDescription: customization.customPlansDescription,
            planRefreshHandler: { [weak self] updatedPlan in
                Task { [weak self] in
                    await MainActor.run { [weak self] in
                        self?.paymentsUIViewController?.reloadData()
                        if updatedPlan != nil {
                            self?.paymentsUIViewController?.showPurchaseSuccessBanner()
                        }
                    }
                }
            },
            extendSubscriptionHandler: { [weak self] in
                Task { [weak self] in
                    await MainActor.run { [weak self] in
                        self?.paymentsUIViewController?.extendSubscriptionSelection()
                    }
                }
            }
        )
        
        await MainActor.run {
            self.paymentsUIViewController = paymentsUIViewController
            paymentsUIViewController.viewModel = viewModel
            paymentsUIViewController.mode = mode
            
            if mode != .signup {
                showPlanViewController(paymentsViewController: paymentsUIViewController)
            }
        }
        
        do {
            try await viewModel?.fetchPlans()
            unfinishedPurchasePlan = purchaseManager.unfinishedPurchasePlan
            await MainActor.run {
                if mode == .signup {
                    showPlanViewController(paymentsViewController: paymentsUIViewController)
                } else {
                    paymentsUIViewController.reloadData()
                }
            }
        } catch let error {
            await MainActor.run {
                showError(error: error)
            }
        }
    }
    
    private func showPaymentsUI(servicePlan: Either<ServicePlanDataServiceProtocol, PlansDataSourceProtocol>, backendFetch: Bool) {
        let paymentsUIViewController = UIStoryboard.instantiate(
            PaymentsUIViewController.self, storyboardName: storyboardName, inAppTheme: customization.inAppTheme
        )
        paymentsUIViewController.delegate = self
        paymentsUIViewController.onDohTroubleshooting = { [weak self] in
            self?.onDohTroubleshooting()
        }

        viewModel = PaymentsUIViewModel(mode: mode,
                                        storeKitManager: storeKitManager,
                                        planService: planService,
                                        shownPlanNames: shownPlanNames,
                                        clientApp: clientApp,
                                        customPlansDescription: customization.customPlansDescription) { [weak self] updatedPlan in
            DispatchQueue.main.async { [weak self] in
                self?.paymentsUIViewController?.reloadData()
                if updatedPlan != nil {
                    self?.paymentsUIViewController?.showPurchaseSuccessBanner()
                }
            }
        } extendSubscriptionHandler: { [weak self] in
            DispatchQueue.main.async { [weak self] in
                self?.paymentsUIViewController?.extendSubscriptionSelection()
            }
        }
        self.paymentsUIViewController = paymentsUIViewController
        paymentsUIViewController.viewModel = viewModel
        paymentsUIViewController.mode = mode
        if mode != .signup {
            showPlanViewController(paymentsViewController: paymentsUIViewController)
        }
        
        viewModel?.fetchPlans(backendFetch: backendFetch) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.unfinishedPurchasePlan = self.purchaseManager.unfinishedPurchasePlan
                if self.mode == .signup {
                    self.showPlanViewController(paymentsViewController: paymentsUIViewController)
                } else {
                    paymentsUIViewController.reloadData()
                }
            case .failure(let error):
                DispatchQueue.main.async { [weak self] in
                    self?.showError(error: error)
                }
            }
        }
    }
    
    private func showPlanViewController(paymentsViewController: PaymentsUIViewController) {
        if mode == .signup {
            viewController?.navigationController?.pushViewController(paymentsViewController, animated: true)
            completionHandler?(.open(vc: paymentsViewController, opened: true))
            if self.unfinishedPurchasePlan != nil {
                showProcessingTransactionAlert()
            }
        } else {
            switch presentationType {
            case .modal:
                var topViewController: UIViewController?
                let keyWindow = UIApplication.firstKeyWindow
                if var top = keyWindow?.rootViewController {
                    while let presentedViewController = top.presentedViewController {
                        top = presentedViewController
                    }
                    topViewController = top
                }
                paymentsViewController.modalPresentation = true
                let navigationController = LoginNavigationViewController(rootViewController: paymentsViewController)
                navigationController.overrideUserInterfaceStyle = customization.inAppTheme().userInterfaceStyle
                navigationController.modalPresentationStyle = .pageSheet
                topViewController?.present(navigationController, animated: true)
                completionHandler?(.open(vc: paymentsViewController, opened: true))
            case .none:
                paymentsViewController.modalPresentation = false
                completionHandler?(.open(vc: paymentsViewController, opened: false))
            }
        }
    }
    
    private func showError(error: Error) {
        if let error = error as? StoreKitManagerErrors {
            self.showError(message: error.userFacingMessageInPayments, error: error)
        } else if let error = error as? ResponseError {
            self.showError(message: error.localizedDescription, error: error)
        } else if let error = error as? AuthErrors, error.isInvalidAccessToken {
            // silence invalid access token error
        } else {
            self.showError(message: error.userFacingMessageInPayments, error: error)
        }
        finishCallback(reason: .purchaseError(error: error))
    }
    
    private func showError(message: String, error: Error) {
        guard localErrorMessages else { return }
        alertManager.showError(message: message, error: error)
    }
    
    private var localErrorMessages: Bool {
        return mode != .signup
    }
    
    private func finishCallback(reason: PaymentsUIResultReason) {
        completionHandler?(reason)
    }
    
    private func showProcessingTransactionAlert(isError: Bool = false) {
        guard unfinishedPurchasePlan != nil else { return }
        
        let title = isError ? PUITranslations.plan_unfinished_error_title.l10n : PUITranslations._payments_warning.l10n
        let message = isError ? PUITranslations.plan_unfinished_error_desc.l10n : PUITranslations.plan_unfinished_desc.l10n
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let retryAction = UIAlertAction(title: isError ? PUITranslations.plan_unfinished_error_retry_button.l10n : PSTranslation._core_retry.l10n, style: .default, handler: { _ in
            
            // unregister from being notified on the transactions — we're finishing immediately
            guard let unfinishedPurchasePlan = self.unfinishedPurchasePlan else { return }
            self.storeKitManager.stopBeingNotifiedWhenTransactionsWaitingForTheSignupAppear()
            self.finishCallback(reason: .purchasedPlan(accountPlan: unfinishedPurchasePlan))
        })
        retryAction.accessibilityLabel = "DialogRetryButton"
        alertController.addAction(retryAction)
        let cancelAction = UIAlertAction(title: PUITranslations._core_cancel_button.l10n, style: .default) { _ in
            // close Payments UI
            self.completionHandler?(.close)
        }
        cancelAction.accessibilityLabel = "DialogCancelButton"
        alertController.addAction(cancelAction)
        paymentsUIViewController?.present(alertController, animated: true, completion: nil)
    }

    private func refreshPlans() async {
        do {
            try await viewModel?.fetchPlans()
            Task { @MainActor in
                paymentsUIViewController?.reloadData()
            }
        } catch {
            PMLog.info("Failed to fetch plans when PaymentsUIViewController will appear: \(error)")
        }
    }
}

// MARK: PaymentsUIViewControllerDelegate

extension PaymentsUICoordinator: PaymentsUIViewControllerDelegate {
    func viewControllerWillAppear(isFirstAppearance: Bool) {
        // Plan data should not be refreshed on first appear because at that time data are freshly loaded. Here must be covered situations when
        // app goes from background for example.
        guard !isFirstAppearance else { return }
        if FeatureFactory.shared.isEnabled(.dynamicPlans) {
            Task {
                await refreshPlans()
            }
        }
    }

    func userDidCloseViewController() {
        if presentationType == .modal, mode != .signup {
            paymentsUIViewController?.dismiss(animated: true, completion: nil)
        } else {
            paymentsUIViewController?.navigationController?.popViewController(animated: true)
        }
        completionHandler?(.close)
    }
    
    func userDidDismissViewController() {
        completionHandler?(.close)
    }

    func userDidSelectPlan(plan: AvailablePlansPresentation, completionHandler: @escaping () -> Void) {
        guard let inAppPlan = plan.availablePlan else {
            completionHandler()
            return
        }
        userDidSelectPlan(plan: inAppPlan, addCredits: false, completionHandler: completionHandler)
    }
    
    func userDidSelectPlan(plan: PlanPresentation, addCredits: Bool, completionHandler: @escaping () -> Void) {
        userDidSelectPlan(plan: plan.accountPlan, addCredits: false, completionHandler: completionHandler)
    }

    private func userDidSelectPlan(plan: InAppPurchasePlan, addCredits: Bool, completionHandler: @escaping () -> Void) {
        // unregister from being notified on the transactions — you will get notified via `buyPlan` completion block
        storeKitManager.stopBeingNotifiedWhenTransactionsWaitingForTheSignupAppear()
        purchaseManager.buyPlan(plan: plan, addCredits: addCredits) { [weak self] callback in
            completionHandler()
            guard let self = self else { return }
            switch callback {
            case .planPurchaseProcessingInProgress(let plan):
                ObservabilityEnv.report(.paymentLaunchBillingTotal(status: .planPurchaseProcessingInProgress))
                self.unfinishedPurchasePlan = plan
                self.finishCallback(reason: .planPurchaseProcessingInProgress(accountPlan: plan))
                ObservabilityEnv.report(.paymentPurchaseTotal(status: .planPurchaseProcessingInProgress))
                ObservabilityEnv.report(.planSelectionCheckoutTotal(status: .processingInProgress, plan: self.getPlanNameForObservabilityPurposes(plan: plan)))
            case .purchasedPlan(let plan):
                ObservabilityEnv.report(.paymentLaunchBillingTotal(status: .success))
                self.unfinishedPurchasePlan = self.purchaseManager.unfinishedPurchasePlan
                self.finishCallback(reason: .purchasedPlan(accountPlan: plan))
                ObservabilityEnv.report(.paymentPurchaseTotal(status: .success))
                ObservabilityEnv.report(.planSelectionCheckoutTotal(status: .successful, plan: self.getPlanNameForObservabilityPurposes(plan: plan)))
            case .toppedUpCredits:
                ObservabilityEnv.report(.paymentLaunchBillingTotal(status: .success))
                self.unfinishedPurchasePlan = self.purchaseManager.unfinishedPurchasePlan
                self.finishCallback(reason: .toppedUpCredits)
                ObservabilityEnv.report(.paymentPurchaseTotal(status: .success))
                ObservabilityEnv.report(.planSelectionCheckoutTotal(status: .successful, plan: self.getPlanNameForObservabilityPurposes(plan: plan)))
            case .purchaseError(let error, let processingPlan):
                ObservabilityEnv.report(.paymentLaunchBillingTotal(status: .purchaseError))
                if let processingPlan = processingPlan {
                    self.unfinishedPurchasePlan = processingPlan
                }
                ObservabilityEnv.report(.paymentPurchaseTotal(status: .purchaseError))
                ObservabilityEnv.report(.planSelectionCheckoutTotal(status: .failed, plan: self.getPlanNameForObservabilityPurposes(plan: plan)))
                self.showError(error: error)
            case let .apiMightBeBlocked(message, originalError, processingPlan):
                ObservabilityEnv.report(.paymentLaunchBillingTotal(status: .apiBlocked))
                if let processingPlan = processingPlan {
                    self.unfinishedPurchasePlan = processingPlan
                }
                self.unfinishedPurchasePlan = processingPlan
                ObservabilityEnv.report(.paymentPurchaseTotal(status: .apiBlocked))
                ObservabilityEnv.report(.planSelectionCheckoutTotal(status: .apiMightBeBlocked, plan: self.getPlanNameForObservabilityPurposes(plan: plan)))
                // TODO: should we handle it ourselves? or let the client do it?
                self.finishCallback(reason: .apiMightBeBlocked(message: message, originalError: originalError))
            case .purchaseCancelled:
                ObservabilityEnv.report(.paymentLaunchBillingTotal(status: .canceled))
                ObservabilityEnv.report(.paymentPurchaseTotal(status: .canceled))
                ObservabilityEnv.report(.planSelectionCheckoutTotal(status: .canceled, plan: self.getPlanNameForObservabilityPurposes(plan: plan)))
            }
        }
    }
    
    func getPlanNameForObservabilityPurposes(plan: InAppPurchasePlan) -> PlanName {
        if plan.protonName == InAppPurchasePlan.freePlanName || plan.protonName.contains("free") {
            return .free
        } else {
            return .paid
        }
    }
    
    func planPurchaseError() {
        if mode == .signup {
            self.showProcessingTransactionAlert(isError: true)
        }
    }
}

private extension UIStoryboard {
    static func instantiate<T: UIViewController>(
        _ controllerType: T.Type, storyboardName: String, inAppTheme: () -> InAppTheme
    ) -> T {
        instantiate(storyboardName: storyboardName, controllerType: controllerType, inAppTheme: inAppTheme)
    }
}

#endif
