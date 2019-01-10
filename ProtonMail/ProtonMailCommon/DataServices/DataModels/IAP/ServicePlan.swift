//
//  ServicePlan.swift
//  ProtonMail - Created on 20/08/2018.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation

enum ServicePlan: String {
    case free = "free"
    case plus = "plus"
    case pro = "professional"
    case visionary = "visionary"
    
    internal func fetchDetails() -> ServicePlanDetails? {
        return ServicePlanDataService.shared.detailsOfServicePlan(named: self.rawValue)
    }
    
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
