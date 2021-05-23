//
//  ServicePlanSubscription.swift
//  PMPayments - Created on 31/08/2018.
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

public class ServicePlanSubscription: NSObject, Codable {
    public let start, end: Date?
    public let cycle: Int?
    internal var paymentMethods: [PaymentMethod]?
    public let planDetails: [ServicePlanDetails]?
    private let defaultPlanDetails: ServicePlanDetails?
    let couponCode: String?

    /// Special coupons have to be set from app using this library
    public static var specialCoupons: [String] = [String]()

    internal init(start: Date?, end: Date?, planDetails: [ServicePlanDetails]?, defaultPlanDetails: ServicePlanDetails?, paymentMethods: [PaymentMethod]?, couponCode: String? = nil, cycle: Int? = nil) {
        self.start = start
        self.end = end
        self.planDetails = planDetails
        self.paymentMethods = paymentMethods
        self.defaultPlanDetails = defaultPlanDetails
        self.couponCode = couponCode
        self.cycle = cycle
    }
}

extension ServicePlanSubscription {
    public var plans: [AccountPlan] {
        return self.planDetails?.compactMap({ AccountPlan(rawValue: $0.name) }) ?? [.free]
    }

    public var details: ServicePlanDetails {
        return self.planDetails?.merge() ?? self.defaultPlanDetails ?? ServicePlanDetails(features: 0, iD: "", maxAddresses: 0, maxDomains: 0, maxMembers: 0, maxSpace: 0, maxVPN: 0, name: "", quantity: 0, services: 0, title: "", type: 0)
    }

    public var hasExistingProtonSubscription: Bool {
        var existingSubscription = false

        self.planDetails?.map({ AccountPlan(rawValue: $0.name) }).forEach({ (plan) in
            if let plan = plan {
                if !(plan == .free || plan == .trial) {
                    existingSubscription = true
                }
            } else {
                existingSubscription = true
            }
        })
        return existingSubscription
    }

    public var hadOnlinePayments: Bool {
        guard let allMethods = self.paymentMethods else {
            return false
        }
        return allMethods.map { $0.type }.contains(.card)
    }

    public var endDate: Date? {
        return end
    }

    public var hasSpecialCoupon: Bool {
        guard let couponCode = couponCode else {
            return false
        }
        return ServicePlanSubscription.specialCoupons.contains(couponCode)
    }
}
