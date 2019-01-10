//
//  ServicePlanSubscription.swift
//  ProtonMail - Created on 31/08/2018.
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

class ServicePlanSubscription: NSObject, Codable {
    internal let start, end: Date?
    internal var paymentMethods: [PaymentMethod]?
    private let planDetails: [ServicePlanDetails]?
    
    internal init(start: Date?, end: Date?, planDetails: [ServicePlanDetails]?, paymentMethods: [PaymentMethod]?) {
        self.start = start
        self.end = end
        self.planDetails = planDetails
        self.paymentMethods = paymentMethods
        super.init()
    }
}

extension ServicePlanSubscription {
    internal var plan: ServicePlan {
        return self.planDetails?.compactMap({ ServicePlan(rawValue: $0.name) }).first ?? .free
    }
    
    internal var details: ServicePlanDetails {
        return self.planDetails?.merge() ?? ServicePlanDataService.shared.defaultPlanDetails ?? ServicePlanDetails(features: 0, iD: "", maxAddresses: 0, maxDomains: 0, maxMembers: 0, maxSpace: 0, maxVPN: 0, name: "", quantity: 0, services: 0, title: "", type: 0)
    }
    
    internal var hadOnlinePayments: Bool {
        guard let allMethods = self.paymentMethods else {
            return false
        }
        return allMethods.map { $0.type }.contains(.card)
    }
}
