//
//  ServicePlan.swift
//  ProtonMail - Created on 20/08/2018.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation

enum ServicePlan: String {
    case free = "free"
    case plus = "plus"
    case pro = "professional"
    case visionary = "visionary"
    
    
    // FIXME: localization
    internal var subheader: (String, UIColor) {
        switch self {
        case .free: return ("Free", UIColor.ProtonMail.ServicePlanFree)
        case .plus: return ("Plus", UIColor.ProtonMail.ServicePlanPlus)
        case .pro: return ("Professional", UIColor.ProtonMail.ServicePlanPro)
        case .visionary: return ("Visionary", UIColor.ProtonMail.ServicePlanVisionary)
        }
    }
    
    // FIXME: localization
    internal var headerText: String {
        switch self {
        case .free: return LocalString._free_header
        case .plus: return LocalString._plus_header
        case .pro: return LocalString._pro_header
        case .visionary: return LocalString._vis_header
        }
    }
    
    internal var storeKitProductId: String? {
        switch self {
        case .free, .pro, .visionary: return nil
        case .plus: return "ios_plus_12_usd_non_renewing"
        }
    }
    
    internal init?(storeKitProductId: String) {
        guard storeKitProductId == ServicePlan.plus.storeKitProductId else {
            return nil
        }
        self = .plus
    }
}
