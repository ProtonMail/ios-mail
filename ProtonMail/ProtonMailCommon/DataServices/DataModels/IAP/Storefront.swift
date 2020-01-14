//
//  Storefront.swift
//  ProtonMail - Created on 18/12/2018.
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

class Storefront: NSObject {
    private var servicePlanService: ServicePlanDataService
    private var userService: UserDataService
    
    var plan: ServicePlan
    var details: ServicePlanDetails?
    var others: [ServicePlan]
    var title: String
    var canBuyMoreCredits: Bool
    @objc dynamic var credits: Int
    @objc dynamic var subscription: ServicePlanSubscription?
    @objc dynamic var isProductPurchasable: Bool
    
    private var subscriptionObserver: NSKeyValueObservation!
    
    init(plan: ServicePlan, servicePlanService: ServicePlanDataService, userService: UserDataService) {
        self.servicePlanService = servicePlanService
        self.userService = userService
        
        self.plan = plan
        self.details = servicePlanService.detailsOfServicePlan(named: plan.rawValue)
        self.others = []
        self.title = plan.subheader.0
        
        self.isProductPurchasable = ( plan == .plus
                                        && servicePlanService.currentSubscription?.plan == .free
                                        && StoreKitManager.default.readyToPurchaseProduct() )
        self.canBuyMoreCredits = false
        self.credits = userService.userInfo?.credit ?? 0
        super.init()
    }
    
    init(subscription: ServicePlanSubscription, servicePlanService: ServicePlanDataService, userService: UserDataService) {
        self.servicePlanService = servicePlanService
        self.userService = userService
        
        self.subscription = subscription
        self.plan = subscription.plan
        self.details = subscription.details
        self.others = Array<ServicePlan>(arrayLiteral: .free, .plus).filter({ $0 != subscription.plan })
        
        self.title = LocalString._menu_service_plan_title
        self.isProductPurchasable = false
        
        // only plus, payed via apple
        self.canBuyMoreCredits = ( subscription.plan == .plus && !subscription.hadOnlinePayments )
        self.credits = userService.userInfo?.credit ?? 0
        super.init()

        self.subscriptionObserver = self.servicePlanService.observe(\.currentSubscription) { [unowned self] shared, change in
            guard let newSubscription = shared.currentSubscription else { return }
            DispatchQueue.main.async {
                self.plan = newSubscription.plan
                self.details = newSubscription.details
                self.others = Array<ServicePlan>(arrayLiteral: .free, .plus).filter({ $0 != newSubscription.plan })
                self.credits = self.userService.userInfo?.credit ?? 0
                self.subscription = shared.currentSubscription
            }
        }
    }
    
    init(creditsFor subscription: ServicePlanSubscription, servicePlanService: ServicePlanDataService, userService: UserDataService) {
        self.servicePlanService = servicePlanService
        self.userService = userService
        
        self.subscription = subscription
        self.plan = subscription.plan
        self.title = LocalString._buy_more_credits
        self.others = []
        
        // Plus, payed via apple, storekit is ready
        self.isProductPurchasable = ( subscription.plan == .plus
                                        && !subscription.hadOnlinePayments
                                        && StoreKitManager.default.readyToPurchaseProduct() )
        self.credits = userService.userInfo?.credit ?? 0
        self.canBuyMoreCredits = false
        
        super.init()
    }
    
    func buyProduct(successHandler: @escaping ()->Void,
                    errorHandler: @escaping (Error)->Void)
    {
        guard let productId = self.plan.storeKitProductId else { return }
        self.isProductPurchasable = false
        
        let successWrapper: ()->Void = {
            DispatchQueue.main.async {
                successHandler()
            }
        }
        let errorWrapper: (Error)->Void = { [weak self] error in
            DispatchQueue.main.async {
                self?.isProductPurchasable = true
                errorHandler(error)
            }
        }
        let deferredCompletion: ()->Void = {
            // TODO: nothing special
        }
        let canceledCompletion: ()->Void = { [weak self] in
            DispatchQueue.main.async {
                self?.isProductPurchasable = StoreKitManager.default.readyToPurchaseProduct()
            }
        }
        StoreKitManager.default.refreshHandler = canceledCompletion
        StoreKitManager.default.purchaseProduct(withId: productId, successCompletion: successWrapper, errorCompletion: errorWrapper, deferredCompletion: deferredCompletion)
    }
}

