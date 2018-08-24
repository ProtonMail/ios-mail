//
//  ServicePlan.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 20/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

enum ServicePlan: String {
    case free = "ProtonMail Free" // FIXME: change to iDs?
    case plus = "ziWi-ZOb28XR4sCGFCEpqQbd1FITVWYfTfKYUmV_wKKR3GsveN4HZCh9er5dhelYylEp-fhjBbUPDMHGU699fw=="
    case pro = "j_hMLdlh76xys5eR2S3OM9vlAgYylGQBiEzDeXLw1H-huHy2jwjwVqcKAPcdd6z2cXoklLuQTegkr3gnJXCB9w=="
    case visionary = "m-dPNuHcP8N4xfv6iapVg2wHifktAD1A1pFDU95qo5f14Vaw8I9gEHq-3GACk6ef3O12C3piRviy_D43Wh7xxQ=="
    
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
        return self.planDetails?.compactMap({ ServicePlan(rawValue: $0.iD) }).first ?? .free
    }
    var details: ServicePlanDetails {
        return self.planDetails?.merge() ?? ServicePlanDetails.free
    }
    
    let planDetails: [ServicePlanDetails]?
    let start, end: Date?
}

extension Array where Element == ServicePlanDetails {
    func merge() -> ServicePlanDetails? {
        let basicPlans = self.filter({ ServicePlan(rawValue: $0.iD) != nil })
        guard let basic = basicPlans.first else {
            return nil
        }
        return self.reduce(basic, { (result, next) -> ServicePlanDetails in
            return (next != basic) ? (result + next) : result
        })
    }
}
