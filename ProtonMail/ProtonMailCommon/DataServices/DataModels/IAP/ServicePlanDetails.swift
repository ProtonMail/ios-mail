//
//  ServicePlan.swift
//  ProtonMail - Created on 16/08/2018.
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

struct ServicePlanDetails: Codable {
    let features: Int
    let iD: String?
    let maxAddresses: Int
    let maxDomains: Int
    let maxMembers: Int
    let maxSpace: Int64
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
