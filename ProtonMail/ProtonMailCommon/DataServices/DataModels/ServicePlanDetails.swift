//
//  ServicePlan.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 16/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

struct ServicePlanDetails: Codable {
    static var free: ServicePlanDetails = .init(amount: 150, currency: "USD", cycle: 0, features: 0, iD: "ProtonMail Free", maxAddresses: 5, maxDomains: 0, maxMembers: 1, maxSpace: 500*1024, maxVPN: 0, name: "ProtonMail Free", quantity: 150, services: 0, title: "ProtonMail Free", type: 0)
    
    let amount: Int
    let currency: String
    let cycle: Int
    let features: Int
    let iD: String
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
        // FIXME: implement upgrade logic
        return left
    }
    
    static func ==(left: ServicePlanDetails, right: ServicePlanDetails) -> Bool {
        return left.iD == right.iD
    }
}
