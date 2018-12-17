//
//  Subscription.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 31/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

class Subscription: NSObject, Codable {
    internal let start, end: Date?
    internal var paymentMethods: [PaymentMethod]?
    private let planDetails: [ServicePlanDetails]?
    
    internal init(start: Date?, end: Date?, planDetails: [ServicePlanDetails]?, paymentMethods: [PaymentMethod]?) {
        self.start = start
        self.end = end
        self.planDetails = planDetails
        self.paymentMethods = paymentMethods
        super.init()
    }
}

extension Subscription {
    internal var plan: ServicePlan {
        return self.planDetails?.compactMap({ ServicePlan(rawValue: $0.name) }).first ?? .free
    }
    
    internal var details: ServicePlanDetails {
        return self.planDetails?.merge() ?? ServicePlanDataService.shared.defaultPlanDetails ?? ServicePlanDetails(features: 0, iD: "", maxAddresses: 0, maxDomains: 0, maxMembers: 0, maxSpace: 0, maxVPN: 0, name: "", quantity: 0, services: 0, title: "", type: 0)
    }
    
    internal var hadOnlinePayments: Bool {
        guard let allMethods = self.paymentMethods else {
            return false
        }
        return allMethods.map { $0.type }.contains(.card)
    }
}
