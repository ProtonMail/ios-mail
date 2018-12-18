//
//  Storefront.swift
//  ProtonMail - Created on 18/12/2018.
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

class Storefront: NSObject {
    var subscription: Subscription?
    var plan: ServicePlan
    var details: ServicePlanDetails
    var others: [ServicePlan]
    var title: String
    
    var canBuyMoreCredits: Bool = false
    var isProductPurchasable: Bool = false
    
    init(plan: ServicePlan) {
        self.plan = plan
        self.details = plan.fetchDetails()!
        self.others = []
        self.title = plan.subheader.0
        
        if plan == .plus, ServicePlanDataService.shared.currentSubscription?.plan == .free {
            self.isProductPurchasable = true
        }
    }
    
    init(subscription: Subscription) {
        self.subscription = subscription
        self.plan = subscription.plan
        self.details = subscription.details
        self.title = LocalString._menu_service_plan_title
        
        // FIXME: only plus
        self.others = Array<ServicePlan>.init(arrayLiteral: .free, .plus, .pro, .visionary).filter({ $0 != subscription.plan })
        
        //FIXME: only plus, payed via apple, expired
        if subscription.plan != .free, // == .plus
            !subscription.hadOnlinePayments/*,
            ServicePlanDataService.shared.currentSubscription?.end?.compare(Date()) == .orderedAscending */
        {
            self.canBuyMoreCredits = true
        }
    }
}

