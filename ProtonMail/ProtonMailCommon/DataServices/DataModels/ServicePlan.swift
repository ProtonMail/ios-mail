//
//  ServicePlan.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 20/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

enum ServicePlan: String {
    case free = "free"
    case plus = "plus"
    case pro = "professional"
    case visionary = "visionary"
    
    func fetchDetails() -> ServicePlanDetails? {
        return ServicePlanDataService.detailsOfServicePlan(coded: self.rawValue)
    }
    
    // FIXME: localization, colors
    var subheader: (String, UIColor) {
        switch self {
        case .free: return ("Free", UIColor.ProtonMail.ServicePlanFree)
        case .plus: return ("Plus", UIColor.ProtonMail.ServicePlanPlus)
        case .pro: return ("Professional", UIColor.ProtonMail.ServicePlanPro)
        case .visionary: return ("Visionary", UIColor.ProtonMail.ServicePlanVisionary)
        }
    }
    
    // FIXME: localization
    var headerText: String {
        switch self {
        case .free: return "For individuals looking to benefit from secure communication at no cost"
        case .plus: return "For individuals that need more capacity, customization and advanced features"
        case .pro: return "For organizations that need multi-user support nd additional productivity features"
        case .visionary: return "For power users and groups of people that value full anonymity and privacy"
        }
    }
    
    var storeKitProductId: String? {
        switch self {
        case .free, .pro, .visionary: return nil
        case .plus: return "Test_ProtonMail_Plus_3" // FIXME: use non-test id from AppstroreConnect
        }
    }
    
    init?(storeKitProductId: String) {
        guard storeKitProductId == ServicePlan.plus.storeKitProductId else {
            return nil
        }
        self = .plus
    }
}

struct Subscription: Codable {
    var plan: ServicePlan {
        return self.planDetails?.compactMap({ ServicePlan(rawValue: $0.name) }).first ?? .free
    }
    var details: ServicePlanDetails {
        return self.planDetails?.merge() ?? ServicePlanDataService.defaultPlanDetails ?? ServicePlanDetails(amount: 0, currency: "", cycle: 0, features: 0, iD: "", maxAddresses: 0, maxDomains: 0, maxMembers: 0, maxSpace: 0, maxVPN: 0, name: "", quantity: 0, services: 0, title: "", type: 0)
    }
    var hadOnlinePayments: Bool {
        guard let allMethods = self.paymentMethods else {
            return false
        }
        return allMethods.map { $0.type }.contains(.card)
    }
    
    let planDetails: [ServicePlanDetails]?
    let start, end: Date?
    var paymentMethods: [PaymentMethod]?
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
