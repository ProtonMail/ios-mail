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
class ServicePlanDataService {
    private static var allPlanDetails: [ServicePlanDetails] = {
        return userCachedStatus.servicePlansDetails ?? []
    }() {
        willSet { userCachedStatus.servicePlansDetails = newValue }
    }
    
    static var defaultPlanDetails: ServicePlanDetails? = {
        return userCachedStatus.defaultPlanDetails
    }() {
        willSet { userCachedStatus.defaultPlanDetails = newValue }
    }
    
    static var currentSubscription: Subscription? = {
        return userCachedStatus.currentSubscription
    }() {
        willSet { userCachedStatus.currentSubscription = newValue }
    }
    
    typealias CompletionHandler = ()->Void
    
    class func updateServicePlans(completion: CompletionHandler? = nil) {
        async {
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
    
    class func updatePaymentMethods(completion: CompletionHandler? = nil) {
        async {
            let paymentMethodsApi = GetPaymentMethodsRequest()
            let paymentMethodsRes = try await(paymentMethodsApi.run())
            self.currentSubscription?.paymentMethods = paymentMethodsRes.methods
            completion?()
        }.catch { _ in
            completion?()
        }
    }
    
    class func updateCurrentSubscription(completion: CompletionHandler? = nil) {
        self.updateServicePlans()
        async {
            let subscriptionApi = GetSubscriptionRequest()
            let subscriptionRes = try await(subscriptionApi.run())
            self.currentSubscription = Subscription(planDetails: subscriptionRes.plans,
                                                    start: subscriptionRes.start,
                                                    end: subscriptionRes.end,
                                                    paymentMethods: nil)
            self.updatePaymentMethods()
            completion?()
        }.catch { error in
            if (error as NSError).code == 22110 {
                self.currentSubscription = Subscription(planDetails: nil, start: nil, end: nil, paymentMethods: nil)
            }
            completion?()
        }
    }
    
    class func detailsOfServicePlan(coded code: String) -> ServicePlanDetails? {
        return self.allPlanDetails.first(where: { $0.name == code })
    }
}
