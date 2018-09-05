//
//  ServicePlan.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 16/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

struct ServicePlanDetails: Codable {
    let features: Int
    let iD: String?
    let maxAddresses: Int
    let maxDomains: Int
    let maxMembers: Int
    let maxSpace: Int
    let maxVPN: Int
    let name: String
    let quantity: Int
    let services: Int
    let title: String
    let type: Int
}

extension ServicePlanDetails: Equatable {
    static func +(left: ServicePlanDetails, right: ServicePlanDetails) -> ServicePlanDetails {
        // TODO: implement upgrade logic
        return left
    }
    
    static func ==(left: ServicePlanDetails, right: ServicePlanDetails) -> Bool {
        return left.name == right.name
    }
}

extension Array where Element == ServicePlanDetails {
    func merge() -> ServicePlanDetails? {
        let basicPlans = self.filter({ ServicePlan(rawValue: $0.name) != nil })
        guard let basic = basicPlans.first else {
            return nil
        }
        return self.reduce(basic, { (result, next) -> ServicePlanDetails in
            return (next != basic) ? (result + next) : result
        })
    }
}
