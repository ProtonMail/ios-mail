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
    private let storeKitManager = StoreKitManager.default
    private var servicePlan: ServicePlanDataService?
    private var paymentsUI: PaymentsUI?
    private var selectedPlan: AccountPlan = .free
    private var planTypes: PlanTypes
    private var loginData: LoginData?
    private weak var existingDelegate: StoreKitManagerDelegate?
    
    init(apiService: APIService, planTypes: PlanTypes) {
        self.api = apiService
        self.planTypes = planTypes
        storeKitSetup()
    }
    
    func startPaymentProcess(signupViewController: SignupViewController?, planShownHandler: (() -> Void)?, completionHandler: @escaping (Result<(), Error>) -> Void) {
        if let servicePlan = servicePlan, let signupViewController = signupViewController {
            paymentsUI = PaymentsUI(servicePlanDataService: servicePlan, planTypes: planTypes)
            
            var shownHandlerCalled = false
            paymentsUI?.showSignupPlans(viewController: signupViewController, completionHandler: { reason in
                switch reason {
                case .open:
                    shownHandlerCalled = true
                    planShownHandler?()
                case .purchasedPlan(let plan):
                    self.selectedPlan = plan
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
        if selectedPlan != .free {
            servicePlan?.updateCurrentSubscription {
                self.storeKitManager.continueRegistrationPurchase {
                    self.restoreExistingDelegate()
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
    
    private func storeKitSetup() {
        let dataStorage = DataStorageImpl()
        let servicePlan = ServicePlanDataService(localStorage: dataStorage, apiService: api)
        self.servicePlan = servicePlan
        storeKitManager.subscribeToPaymentQueue()
        storeKitManager.updateAvailableProductsList()
        storeExistingDelegate()
        storeKitManager.delegate = self
        paymentsUI = PaymentsUI(servicePlanDataService: servicePlan, planTypes: planTypes)
    }
    
    private func storeExistingDelegate() {
        existingDelegate = storeKitManager.delegate
    }
    
    private func restoreExistingDelegate() {
        storeKitManager.delegate = existingDelegate
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

    var servicePlanDataService: ServicePlanDataService? {
        return servicePlan
    }
    
    func reportBugAlert() {
        existingDelegate?.reportBugAlert()
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
    var servicePlansDetails: [ServicePlanDetails]?
    var defaultPlanDetails: ServicePlanDetails?
    var isIAPUpgradePlanAvailable: Bool = false
    var credits: Credits?
    var currentSubscription: ServicePlanSubscription?
}

protocol PaymentErrorCapable: ErrorCapable {
    func showError(error: StoreKitManager.Errors)
    var bannerPosition: PMBannerPosition { get }
}

extension PaymentErrorCapable {
    func showError(error: StoreKitManager.Errors) {
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
