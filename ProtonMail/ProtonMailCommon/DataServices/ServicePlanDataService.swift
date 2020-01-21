//
//  ServicePlanDataService.swift
//  ProtonMail - Created on 17/08/2018.
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

protocol ServicePlanDataStorage: class {
    var servicePlansDetails: [ServicePlanDetails]? { get set }
    var isIAPAvailableOnBE: Bool { get set }
    var defaultPlanDetails: ServicePlanDetails? { get set }
    var currentSubscription: ServicePlanSubscription? { get set }
}

class ServicePlanDataService: NSObject, Service, HasLocalStorage {
    func cleanUp() {
        self.currentSubscription = nil
    }
    
    static func cleanUpAll() {
        // FIXME: how can we cope with this without knowing exact type of localStorage?
    }
    
    
    internal init(localStorage: ServicePlanDataStorage, apiService: APIService) {
        self.localStorage = localStorage
        self.allPlanDetails = localStorage.servicePlansDetails ?? []
        self.isIAPAvailableOnBE = localStorage.isIAPAvailableOnBE
        self.defaultPlanDetails = localStorage.defaultPlanDetails
        self.currentSubscription = localStorage.currentSubscription
        self.apiService = apiService
        super.init()
    }
    
    typealias CompletionHandler = ()->Void
    private let localStorage: ServicePlanDataStorage
    
    let apiService: APIService
    
    private var allPlanDetails: [ServicePlanDetails] {
        willSet { self.localStorage.servicePlansDetails = newValue }
    }
    
    internal var isIAPAvailable: Bool {
        guard #available(iOS 10.0, *),
            self.isIAPAvailableOnBE,
            Bundle.main.bundleIdentifier == "ch.protonmail.protonmail" else
        {
            return false
        }
        return true
    }
    
    private var isIAPAvailableOnBE: Bool {
        willSet { self.localStorage.isIAPAvailableOnBE = newValue }
    }
    
    var defaultPlanDetails: ServicePlanDetails? {
        willSet { self.localStorage.defaultPlanDetails = newValue }
    }
    
    @objc dynamic var currentSubscription: ServicePlanSubscription? {
        willSet { self.localStorage.currentSubscription = newValue }
    }
    
    internal func detailsOfServicePlan(named name: String) -> ServicePlanDetails? {
        return self.allPlanDetails.first(where: { $0.name == name }) ?? self.defaultPlanDetails
    }
    
    
    //tempory data
    var proceedTier54 : Decimal = Decimal(0)
    
}

extension ServicePlanDataService {
    internal func updateServicePlans(completion: CompletionHandler? = nil) {
        async {
            let statusApi = GetIAPStatusRequest(api: self.apiService)
            let statusRes = try await(statusApi.run())
            self.isIAPAvailableOnBE = statusRes.isAvailable ?? false
            
            let servicePlanApi = GetServicePlansRequest(api: self.apiService)
            let servicePlanRes = try await(servicePlanApi.run())
            self.allPlanDetails = servicePlanRes.availableServicePlans ?? []
            
            let defaultServicePlanApi = GetDefaultServicePlanRequest(api: self.apiService)
            let defaultServicePlanRes = try await(defaultServicePlanApi.run())
            self.defaultPlanDetails = defaultServicePlanRes.defaultMailPlan

            completion?()
        }.catch { _ in
            completion?()
        }
    }
    
    internal func updatePaymentMethods(completion: CompletionHandler? = nil) {
        async {
            let paymentMethodsApi = GetPaymentMethodsRequest(api: self.apiService)
            let paymentMethodsRes = try await(paymentMethodsApi.run())
            self.currentSubscription?.paymentMethods = paymentMethodsRes.methods
            completion?()
        }.catch { _ in
            completion?()
        }
    }
    
    internal func updateTier() {
        async {
            //TODO:: workaround, later we need move this into a dynamic way
            if let productId = ServicePlan.plus.storeKitProductId,
                let price = StoreKitManager.default.priceLabelForProduct(id: productId),
                let currency = price.1.currencyCode,
                let countryCode = (price.1 as NSLocale).object(forKey: .countryCode) as? String {
                let proceedRequest = GetAppleTier(api: self.apiService, currency: currency, country: countryCode)
                let proceed = try await(proceedRequest.run())
                self.proceedTier54 = proceed.proceed
            }
        }.catch { _ in
            self.proceedTier54 = Decimal(0)
        }
    }
    
    internal func updateCurrentSubscription(completion: CompletionHandler? = nil) {
        self.updateServicePlans()
        async {
            let subscriptionApi = GetSubscriptionRequest(api: self.apiService)
            let subscriptionRes = try await(subscriptionApi.run())
            self.currentSubscription = subscriptionRes.subscription
            self.updatePaymentMethods()
            completion?()
        }.catch { error in
            if (error as NSError).code == 22110 { // no subscription stands for free/default plan
                self.currentSubscription = ServicePlanSubscription(start: nil, end: nil, planDetails: nil, defaultPlanDetails: self.defaultPlanDetails, paymentMethods: nil)
            }
            completion?()
        }.finally {
            self.updateTier()
        }

    }
}
