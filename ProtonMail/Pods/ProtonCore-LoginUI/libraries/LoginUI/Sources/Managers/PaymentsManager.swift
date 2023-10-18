//
//  PaymentsManager.swift
//  ProtonCore-Login - Created on 01/06/2021.
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
import ProtonCoreDataModel
import ProtonCoreFeatureSwitch
import ProtonCoreServices
import ProtonCorePayments
import ProtonCoreLogin
import ProtonCorePaymentsUI
import ProtonCoreUIFoundations

class PaymentsManager {

    private let api: APIService
    private let payments: Payments
    private var paymentsUI: PaymentsUI?
    private(set) var selectedPlan: InAppPurchasePlan?
    private var loginData: LoginData?
    private weak var existingDelegate: StoreKitManagerDelegate?
    
    init(apiService: APIService,
         iaps: ListOfIAPIdentifiers,
         shownPlanNames: ListOfShownPlanNames,
         clientApp: ClientApp,
         customization: PaymentsUICustomizationOptions,
         reportBugAlertHandler: BugAlertHandler) {
        self.api = apiService
        self.payments = Payments(inAppPurchaseIdentifiers: iaps,
                                 apiService: api,
                                 localStorage: DataStorageImpl(),
                                 reportBugAlertHandler: reportBugAlertHandler)
        storeExistingDelegate()
        payments.storeKitManager.delegate = self
        if FeatureFactory.shared.isEnabled(.dynamicPlans) {
            // In the dynamic plans, fetching available IAPs from StoreKit is done alongside fetching available plans
            self.payments.storeKitManager.subscribeToPaymentQueue()
        } else {
            // Before dynamic plans, to be ready to present the available plans, we must fetch the available IAPs from StoreKit
            payments.storeKitManager.updateAvailableProductsList { [weak self] error in
                self?.payments.storeKitManager.subscribeToPaymentQueue()
            }
        }
        paymentsUI = PaymentsUI(
            payments: payments, clientApp: clientApp, shownPlanNames: shownPlanNames, customization: customization
        )
    }
    
    func startPaymentProcess(signupViewController: SignupViewController,
                             planShownHandler: (() -> Void)?,
                             completionHandler: @escaping (Result<(), Error>) -> Void) {

        if FeatureFactory.shared.isEnabled(.dynamicPlans) {
            // In the dynamic plans, fetching available IAPs from StoreKit is done alongside fetching available plans
            continuePaymentProcess(signupViewController: signupViewController,
                                   planShownHandler: planShownHandler,
                                   completionHandler: completionHandler)
        } else {
            // Before dynamic plans, to be ready to present the available plans, we must fetch the available IAPs from StoreKit
            payments.storeKitManager.updateAvailableProductsList { [weak self] error in
                if let error = error {
                    planShownHandler?()
                    completionHandler(.failure(error))
                    return
                }
                self?.continuePaymentProcess(signupViewController: signupViewController,
                                             planShownHandler: planShownHandler,
                                             completionHandler: completionHandler)
            }
        }
    }

    private func continuePaymentProcess(signupViewController: SignupViewController,
                                        planShownHandler: (() -> Void)?,
                                        completionHandler: @escaping (Result<(), Error>) -> Void) {
        var shownHandlerCalled = false
        paymentsUI?.showSignupPlans(viewController: signupViewController, completionHandler: { [weak self] reason in
            switch reason {
            case .open:
                shownHandlerCalled = true
                planShownHandler?()
            case .purchasedPlan(let plan):
                self?.selectedPlan = plan
                completionHandler(.success(()))
            case .purchaseError(let error):
                if !shownHandlerCalled {
                    planShownHandler?()
                }
                completionHandler(.failure(error))
            case let .apiMightBeBlocked(message, originalError):
                completionHandler(.failure(LoginError.apiMightBeBlocked(message: message, originalError: originalError)))
            case .close:
                break
            case .toppedUpCredits:
                // TODO: some popup?
                completionHandler(.success(()))
            case .planPurchaseProcessingInProgress:
                break
            }
        })
    }
    
    func finishPaymentProcess(loginData: LoginData,
                              completionHandler: @escaping (Result<(InAppPurchasePlan?), Error>) -> Void) {
        self.loginData = loginData
        if selectedPlan != nil {
            // TODO: test purchase process with PlansDataSource object
            switch payments.planService {
            case .left(let planService):
                planService.updateCurrentSubscription { [weak self] in
                    self?.payments.storeKitManager.retryProcessingAllPendingTransactions { [weak self] in
                        var result: InAppPurchasePlan?
                        if planService.currentSubscription?.hasExistingProtonSubscription ?? false {
                            result = self?.selectedPlan
                        }

                        self?.restoreExistingDelegate()
                        self?.payments.storeKitManager.unsubscribeFromPaymentQueue()
                        completionHandler(.success(result))
                    }
                } failure: { error in
                    completionHandler(.failure(error))
                }

            case .right(let planDataSource):
                Task { [weak self] in
                    do {
                        try await planDataSource.fetchCurrentPlan()
                        self?.payments.storeKitManager.retryProcessingAllPendingTransactions { [weak self] in
                            var result: InAppPurchasePlan?
                            if planDataSource.currentPlan?.hasExistingProtonSubscription ?? false {
                                result = self?.selectedPlan
                            }

                            self?.restoreExistingDelegate()
                            self?.payments.storeKitManager.unsubscribeFromPaymentQueue()
                            completionHandler(.success(result))
                        }
                    } catch {
                        completionHandler(.failure(error))
                    }
                }
            }
        } else {
            self.restoreExistingDelegate()
            self.payments.storeKitManager.unsubscribeFromPaymentQueue()
            completionHandler(.success(nil))
        }
    }

    private func storeExistingDelegate() {
        existingDelegate = payments.storeKitManager.delegate
    }
    
    private func restoreExistingDelegate() {
        payments.storeKitManager.delegate = existingDelegate
    }
    
    func planTitle(plan: InAppPurchasePlan?) -> String? {
        guard let plan else { return nil }

        // TODO: test purchase process with PlansDataSource object
        switch self.payments.planService {
        case .left(let planService):
            return planService.detailsOfPlanCorrespondingToIAP(plan)?.titleDescription
        case .right(let planDataSource):
            return planDataSource.detailsOfAvailablePlanCorrespondingToIAP(plan)?.title
        }
    }
}

extension PaymentsManager: StoreKitManagerDelegate {
    var tokenStorage: PaymentTokenStorage? {
        return TokenStorageImp.default
    }

    var isUnlocked: Bool {
        return true
    }

    var isSignedIn: Bool {
        return true
    }

    var activeUsername: String? { loginData?.user.name ?? loginData?.credential.userName }

    var userId: String? { loginData?.user.ID ?? loginData?.credential.userID }
}

class TokenStorageImp: PaymentTokenStorage {
    public static var `default` = TokenStorageImp()
    var token: PaymentToken?
    
    func add(_ token: PaymentToken) {
        self.token = token
    }
    
    func get() -> PaymentToken? {
        return token
    }
    
    func clear() {
        self.token = nil
    }
}
    
class DataStorageImpl: ServicePlanDataStorage {
    var servicePlansDetails: [Plan]?
    var defaultPlanDetails: Plan?
    var paymentsBackendStatusAcceptsIAP: Bool = false
    var credits: Credits?
    var currentSubscription: Subscription?
    var paymentMethods: [PaymentMethod]?
}

protocol PaymentErrorCapable: ErrorCapable {
    func showError(error: StoreKitManagerErrors)
    var bannerPosition: PMBannerPosition { get }
}

extension PaymentErrorCapable {
    func showError(error: StoreKitManagerErrors) {
        if case let .apiMightBeBlocked(message, _) = error {
            showBanner(message: message, button: LUITranslation._core_api_might_be_blocked_button.l10n) { [weak self] in
                self?.onDohTroubleshooting()
            }
        } else {
            guard let errorDescription = error.errorDescription else { return }
            showBanner(message: errorDescription)
        }
    }
    
    func showBanner(message: String, button: String? = nil, action: (() -> Void)? = nil) {
        showBanner(message: message, button: button, action: action, position: bannerPosition)
    }
}

extension PaymentsUIViewController: SignUpErrorCapable, LoginErrorCapable, PaymentErrorCapable {
    var bannerPosition: PMBannerPosition { .top }
}

#endif
