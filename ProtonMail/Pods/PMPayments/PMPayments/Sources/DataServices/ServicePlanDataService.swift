//
//  ServicePlanDataService.swift
//  PMPayments - Created on 17/08/2018.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import AwaitKit
import PromiseKit
import PMCommon

public protocol ServicePlanDataStorage: class {
    var servicePlansDetails: [ServicePlanDetails]? { get set }
    var isIAPUpgradePlanAvailable: Bool { get set }
    var defaultPlanDetails: ServicePlanDetails? { get set }
    var currentSubscription: ServicePlanSubscription? { get set }
}

public class ServicePlanDataService: NSObject, Service {
    private let localStorage: ServicePlanDataStorage
    public let service: APIService
    internal var paymentsApi: PaymentsApiProtocol = PaymentsApiImplementation()

    static public func cleanUpAll() -> Promise<Void> {
        return Promise()
    }

    public func cleanUp() -> Promise<Void> {
        return Promise { seal in
            self.currentSubscription = nil
            seal.fulfill_()
        }
    }

    public init(localStorage: ServicePlanDataStorage, apiService: APIService) {
        self.localStorage = localStorage
        self.allPlanDetails = localStorage.servicePlansDetails ?? []
        self.isIAPUpgradePlanAvailable = localStorage.isIAPUpgradePlanAvailable
        self.defaultPlanDetails = localStorage.defaultPlanDetails
        self.currentSubscription = localStorage.currentSubscription
        self.service = apiService
        super.init()
    }

    public var isIAPAvailable: Bool {
        guard self.isIAPUpgradePlanAvailable else { return false }
        return true
    }

    private var allPlanDetails: [ServicePlanDetails] {
        willSet { self.localStorage.servicePlansDetails = newValue }
    }

    public var isIAPUpgradePlanAvailable: Bool {
        willSet { self.localStorage.isIAPUpgradePlanAvailable = newValue }
    }

    public var defaultPlanDetails: ServicePlanDetails? {
        willSet { self.localStorage.defaultPlanDetails = newValue }
    }

    @objc public dynamic var currentSubscription: ServicePlanSubscription? {
        willSet { self.localStorage.currentSubscription = newValue }
    }

    public func detailsOfServicePlan(named name: String) -> ServicePlanDetails? {
        return self.allPlanDetails.first(where: { $0.name == name }) ?? self.defaultPlanDetails
    }

    public var proceedTier54: Decimal = Decimal(0)
    public var credit: Double?
    public var currency: String?
}

extension ServicePlanDataService {
    public func updateServicePlans(success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        _ = firstly {
            updateServicePlans()
        }.done {
            success()
        }.catch({ error in
            failure(error)
        })
    }

    @discardableResult public func updateServicePlans() -> Promise<Void> {
        return Promise {seal in
            async {
                // get API atatus
                let statusApi = self.paymentsApi.statusRequest(api: self.service)
                let statusRes = try await(statusApi.run())
                self.isIAPUpgradePlanAvailable = statusRes.isAvailable ?? false

                // get service plans
                let servicePlanApi = self.paymentsApi.plansRequest(api: self.service)
                let servicePlanRes = try await(servicePlanApi.run())
                self.allPlanDetails = servicePlanRes.availableServicePlans ?? []

                // get default service plan
                let defaultServicePlanApi = self.paymentsApi.defaultPlanRequest(api: self.service)
                let defaultServicePlanRes = try await(defaultServicePlanApi.run())
                self.defaultPlanDetails = defaultServicePlanRes.defaultMailPlan
                seal.fulfill_()
            }.catch { error in
                seal.reject(error)
            }
        }
    }

    public func updateCurrentSubscription(success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        _ = firstly {
            updateCurrentSubscription()
        }.done {
            success()
        }.catch({ error in
            failure(error)
        })
    }

    public func updateCurrentSubscription() -> Promise<Void> {
        return Promise { seal in
            async {
                let subscriptionApi = self.paymentsApi.getSubscriptionRequest(api: self.service)
                let subscriptionRes = try await(subscriptionApi.run())
                self.currentSubscription = subscriptionRes.subscription
                self.updatePaymentMethods()
                self.updateTier()
                self.paymentsApi.getUser(api: self.service) { result in
                    switch result {
                    case .success(let user):
                        self.credit = Double(user.credit) / 100
                        self.currency = user.currency
                        seal.fulfill_()
                    case .failure:
                        seal.fulfill_()
                    }
                }
            }.catch { error in
                if error.isNoSubscriptionError {
                    // no subscription stands for free/default plan
                    self.currentSubscription = ServicePlanSubscription(start: nil, end: nil, planDetails: nil, defaultPlanDetails: self.defaultPlanDetails, paymentMethods: nil)
                } else {
                    self.currentSubscription = nil
                }
                self.updateTier()
                seal.fulfill_()
            }
        }
    }

    internal func updatePaymentMethods() {
        do {
            let paymentMethodsApi = self.paymentsApi.methodsRequest(api: self.service)
            let paymentMethodsRes = try await(paymentMethodsApi.run())
            self.currentSubscription?.paymentMethods = paymentMethodsRes.methods
        } catch {
            self.currentSubscription?.paymentMethods = nil
        }
    }

    internal func updateTier() {
        self.currentSubscription?.plans.forEach {
            do {
                if let productId = $0.storeKitProductId,
                    let price = StoreKitManager.default.priceLabelForProduct(identifier: productId),
                    let currency = price.1.currencyCode,
                    let countryCode = (price.1 as NSLocale).object(forKey: .countryCode) as? String {
                    let proceedRequest = self.paymentsApi.appleRequest(api: self.service, currency: currency, country: countryCode)
                    let proceed = try await(proceedRequest.run())
                    self.proceedTier54 = proceed.proceed
                } else {
                    self.proceedTier54 = Decimal(0)
                }
            } catch {
                self.proceedTier54 = Decimal(0)
            }
        }
    }
}
