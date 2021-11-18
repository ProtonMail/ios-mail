//
//  PaymentsManager.swift
//  ProtonCore-Login - Created on 01/06/2021.
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

#if canImport(UIKit)
import UIKit
import ProtonCore_Services
import ProtonCore_Payments
import ProtonCore_PaymentsUI
import ProtonCore_UIFoundations

class PaymentsManager {

    private let api: APIService
    private let payments: Payments
    private var paymentsUI: PaymentsUI?
    private(set) var selectedPlan: InAppPurchasePlan?
    private var loginData: LoginData?
    private weak var existingDelegate: StoreKitManagerDelegate?
    
    init(apiService: APIService, iaps: ListOfIAPIdentifiers, reportBugAlertHandler: BugAlertHandler) {
        self.api = apiService
        self.payments = Payments(inAppPurchaseIdentifiers: iaps,
                                 apiService: api,
                                 localStorage: DataStorageImpl(),
                                 reportBugAlertHandler: reportBugAlertHandler)
        payments.storeKitManager.updateAvailableProductsList { [weak self] error in
            self?.payments.storeKitManager.subscribeToPaymentQueue()
        }
        storeExistingDelegate()
        payments.storeKitManager.delegate = self
        paymentsUI = PaymentsUI(payments: payments)
    }
    
    func startPaymentProcess(signupViewController: SignupViewController,
                             planShownHandler: (() -> Void)?,
                             completionHandler: @escaping (Result<(), Error>) -> Void) {

        payments.storeKitManager.updateAvailableProductsList { [weak self] error in

            if let error = error {
                planShownHandler?()
                completionHandler(.failure(error))
                return
            }

            var shownHandlerCalled = false
            self?.paymentsUI?.showSignupPlans(viewController: signupViewController, completionHandler: { [weak self] reason in
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
                default:
                    break
                }
            })

        }
    }
    
    func finishPaymentProcess(loginData: LoginData, completionHandler: @escaping (Result<(), Error>) -> Void) {
        self.loginData = loginData
        if selectedPlan != nil {
            payments.planService.updateCurrentSubscription(updateCredits: false) { [weak self] in
                self?.payments.storeKitManager.continueRegistrationPurchase { [weak self] in
                    self?.restoreExistingDelegate()
                    completionHandler(.success(()))
                }
            } failure: { error in
                completionHandler(.failure(error))
            }
        } else {
            self.restoreExistingDelegate()
            completionHandler(.success(()))
        }
    }

    private func storeExistingDelegate() {
        existingDelegate = payments.storeKitManager.delegate
    }
    
    private func restoreExistingDelegate() {
        payments.storeKitManager.delegate = existingDelegate
    }
    
    var planTitle: String? {
        guard let name = selectedPlan?.protonName else { return nil }
        return servicePlanDataService?.detailsOfServicePlan(named: name)?.titleDescription
    }
}

extension PaymentsManager: StoreKitManagerDelegate {
    var apiService: APIService? {
        return api
    }

    var tokenStorage: PaymentTokenStorage? {
        return TokenStorageImp.default
    }

    var isUnlocked: Bool {
        return true
    }

    var isSignedIn: Bool {
        return true
    }

    var activeUsername: String? {
        switch loginData {
        case .userData(let data):
            return data.user.name
        case .credential(let credential):
            return credential.userName
        case .none:
            return nil
        }
    }

    var userId: String? {
        switch loginData {
        case .userData(let data):
            return data.user.ID
        case .credential(let credential):
            return credential.userID
        case .none:
            return nil
        }
    }

    var servicePlanDataService: ServicePlanDataServiceProtocol? {
        return payments.planService
    }
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
    var isIAPUpgradePlanAvailable: Bool = false
    var credits: Credits?
    var currentSubscription: Subscription?
}

protocol PaymentErrorCapable: ErrorCapable {
    func showError(error: StoreKitManagerErrors)
    var bannerPosition: PMBannerPosition { get }
}

extension PaymentErrorCapable {
    func showError(error: StoreKitManagerErrors) {
        guard let errorDescription = error.errorDescription else { return }
        showBanner(message: errorDescription)
    }
    
    func showBanner(message: String) {
        showBanner(message: message, position: bannerPosition)
    }
}

extension PaymentsUIViewController: SignUpErrorCapable, LoginErrorCapable, PaymentErrorCapable {
    var bannerPosition: PMBannerPosition { .top }
}

#endif
