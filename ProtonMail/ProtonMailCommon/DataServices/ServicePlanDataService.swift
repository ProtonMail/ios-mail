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
    
    static var currentSubscription: Subscription? = {
        return userCachedStatus.currentSubscription
    }() {
        willSet { userCachedStatus.currentSubscription = newValue }
    }
    
    typealias CompletionHandler = ()->Void
    
    class func updateServicePlans(completion: CompletionHandler? = nil) {
        async {
            do {
                let servicePlanApi = GetServicePlansRequest()
                let servicePlanRes = try await(servicePlanApi.run())
                self.allPlanDetails = servicePlanRes.availableServicePlans ?? []
                completion?()
            } catch _ {
                completion?()
            }
        }
    }
    
    class func updateCurrentSubscription(completion: CompletionHandler? = nil) {
        async {
            do {
                let subscriptionApi = GetSubscriptionRequest()
                let subscriptionRes = try await(subscriptionApi.run())
                self.currentSubscription = Subscription(planDetails: subscriptionRes.plans,
                                                        start: subscriptionRes.start,
                                                        end: subscriptionRes.end)
                completion?()
            } catch let error {
                if (error as NSError).code == 22110 {
                    self.currentSubscription = Subscription(planDetails: nil, start: nil, end: nil)
                }
                completion?()
            }
        }
    }
    
    
    
    class func detailsOfServicePlan(coded code: String) -> ServicePlanDetails? {
        return self.allPlanDetails.first(where: { $0.iD == code })
    }
}
