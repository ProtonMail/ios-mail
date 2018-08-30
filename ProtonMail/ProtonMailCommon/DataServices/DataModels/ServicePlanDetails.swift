//
//  ServicePlan.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 16/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

struct ServicePlanDetails: Codable {    
    let amount: Int!
    let currency: String!
    let cycle: Int!
    let features: Int
    let iD: String!
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
        return left.name == right.name
    }
}

struct PaymentMethod: Codable {
    enum PaymentType: String, Codable {
        case other = "other"
        case apple = "apple"
        case card = "card"
        
        init?(rawValue: String) {
            if rawValue == PaymentType.apple.rawValue {
                self = .apple
            } else if rawValue == PaymentType.card.rawValue {
                self = .card
            } else {
                self = .other
            }
        }
    }
    
    let iD: String
    let type: PaymentType
}
