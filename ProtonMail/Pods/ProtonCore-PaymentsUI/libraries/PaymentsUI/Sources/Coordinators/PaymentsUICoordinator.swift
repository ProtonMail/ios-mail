//
//  PaymentsUICoordinator.swift
//  ProtonCore_PaymentsUI - Created on 01/06/2021.
//
//  Copyright (c) 2021 Proton Technologies AG
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

import UIKit
import enum ProtonCore_DataModel.ClientApp
import ProtonCore_Payments
import ProtonCore_Networking
import ProtonCore_UIFoundations
import ProtonCore_CoreTranslation

final class PaymentsUICoordinator {
    
    private var viewController: UIViewController?
    private var presentationType: PaymentsUIPresentationType = .modal
    private var mode: PaymentsUIMode = .signup
    private var completionHandler: ((PaymentsUIResultReason) -> Void)?
    private var viewModel: PaymentsUIViewModelViewModel?
    private var updateCredits: Bool = false

    private let planService: ServicePlanDataServiceProtocol
    private let storeKitManager: StoreKitManagerProtocol
    private let purchaseManager: PurchaseManagerProtocol
    private let shownPlanNames: ListOfShownPlanNames
    private let alertManager: PaymentsUIAlertManager
    private let clientApp: ClientApp
    
    private var processingAccountPlan: InAppPurchasePlan? {
        didSet {
            guard let processingAccountPlan = processingAccountPlan, mode != .signup else { return }
            viewModel?.processingAccountPlan = processingAccountPlan
            paymentsUIViewController?.reloadData()
        }
    }
    
    var paymentsUIViewController: PaymentsUIViewController? {
        didSet { alertManager.viewController = paymentsUIViewController }
    }
    
    init(planService: ServicePlanDataServiceProtocol,
         storeKitManager: StoreKitManagerProtocol,
         purchaseManager: PurchaseManagerProtocol,
         clientApp: ClientApp,
         shownPlanNames: ListOfShownPlanNames,
         alertManager: PaymentsUIAlertManager) {
        self.planService = planService
        self.storeKitManager = storeKitManager
        self.purchaseManager = purchaseManager
        self.shownPlanNames = shownPlanNames
        self.alertManager = alertManager
        self.clientApp = clientApp
    }
    
    func start(viewController: UIViewController?, completionHandler: @escaping ((PaymentsUIResultReason) -> Void)) {
        self.viewController = viewController
        self.mode = .signup
        self.completionHandler = completionHandler
        showPaymentsUI(servicePlan: planService, backendFetch: false)
    }
    
    func start(presentationType: PaymentsUIPresentationType, mode: PaymentsUIMode, backendFetch: Bool, updateCredits: Bool, completionHandler: @escaping ((PaymentsUIResultReason) -> Void)) {
        self.presentationType = presentationType
        self.mode = mode
        self.completionHandler = completionHandler
        self.updateCredits = updateCredits
        showPaymentsUI(servicePlan: planService, backendFetch: backendFetch)
    }

    // MARK: Private methods

    private func showPaymentsUI(servicePlan: ServicePlanDataServiceProtocol, backendFetch: Bool) {

        let paymentsUIViewController = UIStoryboard.instantiate(PaymentsUIViewController.self)
        paymentsUIViewController.delegate = self
        
        viewModel = PaymentsUIViewModelViewModel(mode: mode, storeKitManager: storeKitManager, servicePlan: servicePlan, shownPlanNames: shownPlanNames, clientApp: clientApp, updateCredits: updateCredits,
                                                      planRefreshHandler: { [weak self] in
            DispatchQueue.main.async { [weak self] in
                self?.paymentsUIViewController?.reloadData()
            }
        })
        self.paymentsUIViewController = paymentsUIViewController
        paymentsUIViewController.model = viewModel
        paymentsUIViewController.mode = mode
        if mode != .signup {
            showPlanViewController(paymentsViewController: paymentsUIViewController)
        }
        
        paymentsUIViewController.model?.fetchPlans(backendFetch: backendFetch) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.processingAccountPlan = self.purchaseManager.unfinishedPurchasePlan
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
            if self.processingAccountPlan != nil {
                showProcessingTransactionAlert()
            }
        } else {
            switch presentationType {
            case .modal:
                var topViewController: UIViewController?
                let keyWindow = UIApplication.getInstance()?.windows.filter { $0.isKeyWindow }.first
                if var top = keyWindow?.rootViewController {
                    while let presentedViewController = top.presentedViewController {
                        top = presentedViewController
                    }
                    topViewController = top
                }
                paymentsViewController.modalPresentation = true
                let navigationController = LoginNavigationViewController(rootViewController: paymentsViewController)
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
            self.showError(message: error.userFacingMessageInPayments)
        } else if let error = error as? ResponseError {
            self.showError(message: error.localizedDescription)
        } else {
            self.showError(message: error.userFacingMessageInPayments)
        }
        finishCallback(reason: .purchaseError(error: error))
    }
    
    private func showError(message: String) {
        guard localErrorMessages else { return }
        alertManager.showError(message: message)
    }
    
    private var localErrorMessages: Bool {
        return mode != .signup
    }
    
    private func finishCallback(reason: PaymentsUIResultReason) {
        completionHandler?(reason)
    }
    
    private func showProcessingTransactionAlert(isError: Bool = false) {
        guard processingAccountPlan != nil else { return }
        
        let title = isError ? CoreString._pu_plan_unfinished_error_title : CoreString._warning
        let message = isError ? CoreString._pu_plan_unfinished_error_desc : CoreString._pu_plan_unfinished_desc
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let retryAction = UIAlertAction(title: isError ? CoreString._pu_plan_unfinished_error_retry_button : CoreString._retry, style: .default, handler: { _ in
            
            // unregister from being notified on the transactions — we're finishing immediately
            guard let processingAccountPlan = self.processingAccountPlan else { return }
            self.storeKitManager.stopBeingNotifiedWhenTransactionsWaitingForTheSignupAppear()
            self.finishCallback(reason: .purchasedPlan(accountPlan: processingAccountPlan))
        })
        retryAction.accessibilityLabel = "DialogRetryButton"
        alertController.addAction(retryAction)
        let cancelAction = UIAlertAction(title: CoreString._hv_cancel_button, style: .default) { _ in
            // close Payments UI
            self.completionHandler?(.close)
        }
        cancelAction.accessibilityLabel = "DialogCancelButton"
        alertController.addAction(cancelAction)
        paymentsUIViewController?.present(alertController, animated: true, completion: nil)
    }
}

// MARK: PaymentsUIViewControllerDelegate

extension PaymentsUICoordinator: PaymentsUIViewControllerDelegate {
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
    
    func userDidSelectPlan(plan: PlanPresentation, completionHandler: @escaping () -> Void) {
        // unregister from being notified on the transactions — you will get notified via `buyPlan` completion block
        storeKitManager.stopBeingNotifiedWhenTransactionsWaitingForTheSignupAppear()
        purchaseManager.buyPlan(plan: plan.accountPlan) { [weak self] callback in
            completionHandler()
            guard let self = self else { return }
            switch callback {
            case .planPurchaseProcessingInProgress(let processingPlan):
                self.processingAccountPlan = processingPlan
                self.finishCallback(reason: .planPurchaseProcessingInProgress(accountPlan: processingPlan))
            case .purchasedPlan(let plan):
                self.processingAccountPlan = self.purchaseManager.unfinishedPurchasePlan
                self.finishCallback(reason: .purchasedPlan(accountPlan: plan))
            case .purchaseError(let error, let processingPlan):
                if let processingPlan = processingPlan {
                    self.processingAccountPlan = processingPlan
                }
                self.showError(error: error)
            case .purchaseCancelled:
                break
            }
        }
    }
    
    func planPurchaseError() {
        if mode == .signup {
            self.showProcessingTransactionAlert(isError: true)
        }
    }
}

private extension UIStoryboard {
    static func instantiate<T: UIViewController>(_ controllerType: T.Type) -> T {
        instantiate(storyboardName: "PaymentsUI", controllerType: controllerType)
    }
}
