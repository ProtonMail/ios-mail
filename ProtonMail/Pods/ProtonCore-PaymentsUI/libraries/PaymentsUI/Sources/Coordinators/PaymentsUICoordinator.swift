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
import ProtonCore_Payments
import ProtonCore_Networking
import ProtonCore_UIFoundations

final class PaymentsUICoordinator {
    
    private var viewController: UIViewController?
    private let planTypes: PlanTypes
    private var presentationType: PaymentsUIPresentationType = .modal
    private var mode: PaymentsUIMode = .signup
    private var completionHandler: ((PaymentsUIResultReason) -> Void)?
    private var viewModel: PaymentsUIViewModelViewModel?
    private let paymentsManager = PaymentsManager()
    
    private var processingAccountPlan: AccountPlan? {
        didSet {
            guard let processingAccountPlan = processingAccountPlan else { return }
            viewModel?.processingAccountPlan = processingAccountPlan
            paymentsUIViewController?.reloadData()
        }
    }
    
    var paymentsUIViewController: PaymentsUIViewController?
    
    init(planTypes: PlanTypes) {
        self.planTypes = planTypes
    }
    
    func start(viewController: UIViewController?, servicePlan: ServicePlanDataService, completionHandler: @escaping ((PaymentsUIResultReason) -> Void)) {
        self.viewController = viewController
        self.mode = .signup
        self.completionHandler = completionHandler
        showPaymentsUI(servicePlan: servicePlan, backendFetch: false)
    }
    
    func start(presentationType: PaymentsUIPresentationType, servicePlan: ServicePlanDataService, mode: PaymentsUIMode, backendFetch: Bool, completionHandler: @escaping ((PaymentsUIResultReason) -> Void)) {
        self.presentationType = presentationType
        self.mode = mode
        self.completionHandler = completionHandler
        showPaymentsUI(servicePlan: servicePlan, backendFetch: backendFetch)
    }

    // MARK: Private methods

    private func showPaymentsUI(servicePlan: ServicePlanDataService, backendFetch: Bool) {
        let paymentsUIViewController = UIStoryboard.instantiate(PaymentsUIViewController.self)
        paymentsUIViewController.delegate = self
        
        self.viewModel = PaymentsUIViewModelViewModel(mode: mode, servicePlan: servicePlan, planTypes: planTypes, planRefreshHandler: {
            DispatchQueue.main.async {
                self.paymentsUIViewController?.reloadData()
            }
        })
        self.paymentsUIViewController = paymentsUIViewController
        paymentsUIViewController.model = viewModel
        paymentsUIViewController.mode = mode
        if mode != .signup {
            showPlanViewController(paymentsViewController: paymentsUIViewController)
        }
        
        paymentsUIViewController.model?.fatchPlans(backendFetch: backendFetch) { result in
            switch result {
            case .success:
                self.processingAccountPlan = self.paymentsManager.unfinishedPurchasePlan
                if self.mode == .signup {
                    self.showPlanViewController(paymentsViewController: paymentsUIViewController)
                } else {
                    paymentsUIViewController.reloadData()
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.showError(error: error)
                }
            }
        }
    }
    
    private func showPlanViewController(paymentsViewController: PaymentsUIViewController) {
        if mode == .signup {
            viewController?.navigationController?.pushViewController(paymentsViewController, animated: true)
            completionHandler?(.open(vc: paymentsViewController, opened: true))
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
        if let error = error as? StoreKitManager.Errors {
            // ignore payment cancellation error
            if error == .cancelled || error == .unknown { return }
            self.showError(message: error.localizedDescription)
        } else if let error = error as? ResponseError {
            let message = error.userFacingMessage ?? error.underlyingError?.localizedDescription ?? error.localizedDescription
            self.showError(message: message)
        } else {
            self.showError(message: error.localizedDescription)
        }
        self.finishCallback(reason: .purchaseError(error: error))
    }
    
    private func showError(message: String) {
        if self.localErrorMessages {
            self.paymentsUIViewController?.showError(message: message)
        }
    }
    
    private var localErrorMessages: Bool {
        return mode != .signup
    }
    
    private func finishCallback(reason: PaymentsUIResultReason) {
        self.completionHandler?(reason)
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
    
    func userDidSelectPlan(plan: Plan, completionHandler: @escaping () -> Void) {
        paymentsManager.buyPlan(accountPlan: plan.accountPlan) { callback in
            // callback to the UI that payment is finished
            completionHandler()
            switch callback {
            case .purchasedPlan(let plan, let processingPlan):
                if let processingPlan = processingPlan {
                    self.processingAccountPlan = processingPlan
                }
                self.finishCallback(reason: .purchasedPlan(accountPlan: plan))
            case .purchaseError(let error, let processingPlan):
                if let processingPlan = processingPlan {
                    self.processingAccountPlan = processingPlan
                }
                self.showError(error: error)
            }
        }
    }
}

private extension UIStoryboard {
    static func instantiate<T: UIViewController>(_ controllerType: T.Type) -> T {
        self.instantiate(storyboardName: "PaymentsUI", controllerType: controllerType)
    }
}
