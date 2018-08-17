//
//  ServicePlan.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 16/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

#if !APP_EXTENSION
enum ServicePlan: String {
    case free = "ProtonMail Free" // FIXME: change to iDs?
    case plus = "ProtonMail Plus"
    case pro = "ProtonMail Professional"
    case visionary = "ProtonMail Visionary"
    
    func fetchDetails() -> ServicePlanDetails? {
        return ServicePlanDataService.detailsOfServicePlan(coded: self.rawValue)
    }
    
    // FIXME: codes from UserInfo object
    init?(code: Int) {
        switch code {
        case 0: self = .free
        case 1: self = .plus
        case 2: self = .pro
        case 3: self = .visionary
        default: return nil
        }
    }
}
#endif

struct ServicePlanDetails: Codable {
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
