//
//  ServicePlanDataService.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 17/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import AwaitKit

// FIXME: dependency injection + test this class
class ServicePlanDataService: NSObject {
    static var shared = ServicePlanDataService()
    private override init() {
        super.init()
    }
    
    private var allPlanDetails: [ServicePlanDetails] = {
        return userCachedStatus.servicePlansDetails ?? []
    }() {
        willSet { userCachedStatus.servicePlansDetails = newValue }
    }
    
    var isIAPAvailable: Bool = {
        return userCachedStatus.isIAPAvailable
    }() {
        willSet { userCachedStatus.isIAPAvailable = newValue }
    }
    
    var defaultPlanDetails: ServicePlanDetails? = {
        return userCachedStatus.defaultPlanDetails
    }() {
        willSet { userCachedStatus.defaultPlanDetails = newValue }
    }
    
    @objc dynamic var currentSubscription: Subscription? = {
        return userCachedStatus.currentSubscription
    }() {
        willSet { userCachedStatus.currentSubscription = newValue }
    }
    
    typealias CompletionHandler = ()->Void
    
    func updateServicePlans(completion: CompletionHandler? = nil) {
        async {
            let statusApi = GetIAPStatusRequest()
            let statusRes = try await(statusApi.run())
            self.isIAPAvailable = statusRes.isAvailable ?? false
            
            let servicePlanApi = GetServicePlansRequest()
            let servicePlanRes = try await(servicePlanApi.run())
            self.allPlanDetails = servicePlanRes.availableServicePlans ?? []
            
            let defaultServicePlanApi = GetDefaultServicePlanRequest()
            let defaultServicePlanRes = try await(defaultServicePlanApi.run())
            self.defaultPlanDetails = defaultServicePlanRes.servicePlan

            completion?()
        }.catch { _ in
            completion?()
        }
    }
    
    func updatePaymentMethods(completion: CompletionHandler? = nil) {
        async {
            let paymentMethodsApi = GetPaymentMethodsRequest()
            let paymentMethodsRes = try await(paymentMethodsApi.run())
            self.currentSubscription?.paymentMethods = paymentMethodsRes.methods
            completion?()
        }.catch { _ in
            completion?()
        }
    }
    
    func updateCurrentSubscription(completion: CompletionHandler? = nil) {
        self.updateServicePlans()
        async {
            let subscriptionApi = GetSubscriptionRequest()
            let subscriptionRes = try await(subscriptionApi.run())
            self.currentSubscription = subscriptionRes.subscription
            self.updatePaymentMethods()
            completion?()
        }.catch { error in
            if (error as NSError).code == 22110 { // no subscription stands for free/default plan
                self.currentSubscription = Subscription(start: nil, end: nil, planDetails: nil, paymentMethods: nil)
            }
            completion?()
        }
    }
    
    func detailsOfServicePlan(coded code: String) -> ServicePlanDetails? {
        return self.allPlanDetails.first(where: { $0.name == code }) ?? self.defaultPlanDetails
    }
}
