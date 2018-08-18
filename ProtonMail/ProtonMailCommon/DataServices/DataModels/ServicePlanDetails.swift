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
    case plus = "ziWi-ZOb28XR4sCGFCEpqQbd1FITVWYfTfKYUmV_wKKR3GsveN4HZCh9er5dhelYylEp-fhjBbUPDMHGU699fw=="
    case pro = "j_hMLdlh76xys5eR2S3OM9vlAgYylGQBiEzDeXLw1H-huHy2jwjwVqcKAPcdd6z2cXoklLuQTegkr3gnJXCB9w=="
    case visionary = "m-dPNuHcP8N4xfv6iapVg2wHifktAD1A1pFDU95qo5f14Vaw8I9gEHq-3GACk6ef3O12C3piRviy_D43Wh7xxQ=="
    
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
    
    // FIXME: localization, colors
    var subheader: (String, UIColor) {
        switch self {
        case .free: return ("FREE", .green)
        case .plus: return ("PLUS", .purple)
        case .pro: return ("PROFESSIONAL", .brown)
        case .visionary: return ("VISIONARY", .blue)
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
