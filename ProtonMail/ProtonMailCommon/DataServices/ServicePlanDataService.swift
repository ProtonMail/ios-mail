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
    
    typealias CompletionHandler = ()->Void
    
    class func updateServicePlans(completion: CompletionHandler? = nil) {
        async {
            let servicePlanApi = GetServicePlansRequest()
            let servicePlanRes = try await(servicePlanApi.run())
            self.allPlanDetails = servicePlanRes.availableServicePlans ?? []
            completion?()
        }
    }
    
    // FIXME: what about multiuser?
    class var currentServicePlan: ServicePlan? {
        guard let userInfo = sharedUserDataService.userInfo else { return nil }
        return ServicePlan(code: userInfo.role)
    }
    
    class func detailsOfServicePlan(coded code: String) -> ServicePlanDetails? {
        return self.allPlanDetails.first(where: { $0.iD == code }) // FIXME: change to iDs?
    }
}
