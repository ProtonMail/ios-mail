//
//  ServicePlanSubscription.swift
//  ProtonMail - Created on 31/08/2018.
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

class ServicePlanSubscription: NSObject, Codable {
    internal let start, end: Date?
    internal var paymentMethods: [PaymentMethod]?
    private let planDetails: [ServicePlanDetails]?
    private let defaultPlanDetails: ServicePlanDetails?
    
    internal init(start: Date?, end: Date?, planDetails: [ServicePlanDetails]?, defaultPlanDetails: ServicePlanDetails?, paymentMethods: [PaymentMethod]?) {
        self.start = start
        self.end = end
        self.planDetails = planDetails
        self.paymentMethods = paymentMethods
        self.defaultPlanDetails = defaultPlanDetails
        super.init()
    }
}

extension ServicePlanSubscription {
    internal var plan: ServicePlan {
        return self.planDetails?.compactMap({ ServicePlan(rawValue: $0.name) }).first ?? .free
    }
    
    internal var details: ServicePlanDetails {
        return self.planDetails?.merge() ?? self.defaultPlanDetails ?? ServicePlanDetails(features: 0, iD: "", maxAddresses: 0, maxDomains: 0, maxMembers: 0, maxSpace: 0, maxVPN: 0, name: "", quantity: 0, services: 0, title: "", type: 0)
    }
    
    internal var hadOnlinePayments: Bool {
        guard let allMethods = self.paymentMethods else {
            return false
        }
        return allMethods.map { $0.type }.contains(.card)
    }
}
