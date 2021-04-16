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
import PMCommon
import PMPayments

class Storefront: NSObject {
    private var servicePlanService: ServicePlanDataService
    private var user: UserInfo
    
    var plan: AccountPlan
    var details: ServicePlanDetails?
    var others: [AccountPlan]
    var title: String
    var canBuyMoreCredits: Bool
    @objc dynamic var credits: Int
    @objc dynamic var subscription: ServicePlanSubscription?
    @objc dynamic var isProductPurchasable: Bool
    
    private var subscriptionObserver: NSKeyValueObservation!
    
    init(plan: AccountPlan, servicePlanService: ServicePlanDataService, user: UserInfo, isHavingVpnPlan: Bool = false) {
        self.servicePlanService = servicePlanService
        self.user = user
        
        self.plan = plan
        self.details = servicePlanService.detailsOfServicePlan(named: plan.rawValue)
        self.others = []
        self.title = plan.subheader.0
        
        self.isProductPurchasable = ( plan == .mailPlus
                                        && servicePlanService.currentSubscription?.plan == .free
                                        && StoreKitManager.default.isReadyToPurchaseProduct()
                                        && !isHavingVpnPlan)

        self.canBuyMoreCredits = false
        self.credits = self.user.credit
        super.init()
    }
    
    init(subscription: ServicePlanSubscription, servicePlanService: ServicePlanDataService, user: UserInfo) {
        self.servicePlanService = servicePlanService
        self.user = user
        
        self.subscription = subscription
        self.plan = subscription.plan
        self.details = subscription.details
        self.others = Array<AccountPlan>(arrayLiteral: .free, .mailPlus).filter({ $0 != subscription.plan })
        
        self.title = LocalString._menu_service_plan_title
        self.isProductPurchasable = false
        
        // only plus, payed via apple
        self.canBuyMoreCredits = ( subscription.plan == .mailPlus && !subscription.hadOnlinePayments )
         self.credits = self.user.credit
        super.init()

        self.subscriptionObserver = self.servicePlanService.observe(\.currentSubscription) { [unowned self] shared, change in
            guard let newSubscription = shared.currentSubscription else { return }
            DispatchQueue.main.async {
                self.plan = newSubscription.plan
                self.details = newSubscription.details
                self.others = Array<AccountPlan>(arrayLiteral: .free, .mailPlus).filter({ $0 != newSubscription.plan })
                self.credits = user.credit
                self.subscription = shared.currentSubscription
            }
        }
    }
    
    init(creditsFor subscription: ServicePlanSubscription, servicePlanService: ServicePlanDataService, user: UserInfo) {
        self.servicePlanService = servicePlanService
        self.user = user
        
        self.subscription = subscription
        self.plan = subscription.plan
        self.title = LocalString._buy_more_credits
        self.others = []
        
        // Plus, payed via apple, storekit is ready
        self.isProductPurchasable = ( subscription.plan == .mailPlus
                                        && !subscription.hadOnlinePayments
                                        && StoreKitManager.default.isReadyToPurchaseProduct() )
        self.credits = user.credit
        self.canBuyMoreCredits = false
        
        super.init()
    }
    
    func buyProduct(successHandler: @escaping ()->Void,
                    errorHandler: @escaping (Error)->Void)
    {
        guard let productId = self.plan.storeKitProductId else { return }
        self.isProductPurchasable = false
        
        let successWrapper: (PaymentToken?)->Void = { _ in
            DispatchQueue.main.async {
                successHandler()
            }
        }
        let errorWrapper: (Error)->Void = { [weak self] error in
            DispatchQueue.main.async {
                if let error = error as? StoreKitManager.Errors, error == StoreKitManager.Errors.cancelled {
                    // don't handle payment cancelled by the user
                } else {
                    self?.isProductPurchasable = true
                    errorHandler(error)
                }
            }
        }
        let deferredCompletion: ()->Void = {
            // TODO: nothing special
        }
        let canceledCompletion: ()->Void = { [weak self] in
            DispatchQueue.main.async {
                self?.isProductPurchasable = StoreKitManager.default.isReadyToPurchaseProduct()
            }
        }
        StoreKitManager.default.refreshHandler = canceledCompletion
        StoreKitManager.default.purchaseProduct(identifier: productId, successCompletion: successWrapper, errorCompletion: errorWrapper, deferredCompletion: deferredCompletion)
    }
}

extension AccountPlan {
    var subheader: (String, UIColor) {
        switch self {
        case .free: return ("Free", UIColor.ProtonMail.ServicePlanFree)
        case .mailPlus: return ("Plus", UIColor.ProtonMail.ServicePlanPlus)
        case .pro: return ("Professional", UIColor.ProtonMail.ServicePlanPro)
        case .visionary: return ("Visionary", UIColor.ProtonMail.ServicePlanVisionary)
        default: return ("Free", UIColor.ProtonMail.ServicePlanFree)
        }
    }
    
    var headerText: String {
        switch self {
        case .free: return LocalString._free_header
        case .mailPlus: return LocalString._plus_header
        case .pro: return LocalString._pro_header
        case .visionary: return LocalString._vis_header
        default: return LocalString._free_header
        }
    }
}

extension ServicePlanSubscription {
    var plan: AccountPlan {
        var result: AccountPlan = .free
        let mailPlans: [AccountPlan] = [.visionary, .pro, .mailPlus, .free]
        mailPlans.forEach {
            if plans.contains($0) {
                result = $0
            }
        }
        return result
    }
}
