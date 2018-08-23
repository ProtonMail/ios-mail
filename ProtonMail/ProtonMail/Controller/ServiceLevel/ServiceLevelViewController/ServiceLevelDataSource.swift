//
//  ServiceLevelViewModel.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 12/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

protocol ServiceLevelDataSource {
    var delegate: ServiceLevelDataSourceDelegate! { get set }
    var title: String { get }
    var sections: [Section<UIView>] { get }
    func shouldPerformSegue(byItemOn: IndexPath) -> ServiceLevelCoordinator.Destination?
}

extension ServiceLevelDataSource {
    internal func shouldPerformSegue(byItemOn indexPath: IndexPath) -> ServiceLevelCoordinator.Destination? {
        guard let element = self.sections[indexPath.section].elements[indexPath.item] as? ServicePlanCapability else { return nil }
        return element.context as? ServiceLevelCoordinator.Destination
    }
}

class BuyMoreDataSource: ServiceLevelDataSource {
    weak var delegate: ServiceLevelDataSourceDelegate!
    
    let title = "More Credits"
    var plan: ServicePlan?
    var details: ServicePlanDetails?
    internal var sections: [Section<UIView>] = []
    
    func setup(with subscription: Subscription?) {
        guard let subscription = subscription else {
            self.plan = nil
            self.details = nil
            self.sections = []
            return
        }
        self.plan = subscription.plan
        self.details = subscription.details
        self.sections = [ServiceLevelDataFactory.makePlanStatusSection(plan: subscription.plan, details: subscription.details),
                         ServiceLevelDataFactory.makeBuyButtonSection(plan: subscription.plan, delegate: self.delegate),
                         ServiceLevelDataFactory.makeAcknowladgementsSection()].compactMap { $0 }
    }
}

class PlanDetailsDataSource: ServiceLevelDataSource {
    weak var delegate: ServiceLevelDataSourceDelegate!
    
    var title: String {
        return "Get " + (self.plan?.subheader.0 ?? "Plan")
    }
    
    var plan: ServicePlan?
    var details: ServicePlanDetails?
    internal var sections: [Section<UIView>] = []
    
    func setup(with plan: ServicePlan) {
        self.plan = plan
        self.details = plan.fetchDetails()
        
        var capabilities: Section<UIView>?
        var footer: Section<UIView>?
        var acknowladgements: Section<UIView>?
        if let details = plan.fetchDetails() {
            capabilities = ServiceLevelDataFactory.makeCapabilitiesSection(plan: plan, details: details)
            if plan == .plus, ServicePlanDataService.currentSubscription?.plan == .free {
                footer = ServiceLevelDataFactory.makeBuyButtonSection(plan: plan, delegate: self.delegate)
                acknowladgements = ServiceLevelDataFactory.makeAcknowladgementsSection()
            } else {
                footer = ServiceLevelDataFactory.makePlanStatusSection(plan: plan, details: details)
            }
        }
        self.sections = [ServiceLevelDataFactory.makeLogoSection(plan: plan),
                         capabilities,
                         footer,
                         acknowladgements].compactMap { $0 }
    }
}

class PlanAndLinksDataSource: ServiceLevelDataSource {
    weak var delegate: ServiceLevelDataSourceDelegate!
    let title = LocalString._menu_service_plan_title
    var plan: ServicePlan?
    var details: ServicePlanDetails?
    internal var sections: [Section<UIView>] = []

    internal func setup(with subscription: Subscription?) {
        guard let subscription = subscription else {
            self.sections = [ServiceLevelDataFactory.makeLinksSection()]
            return
        }
        var buyLink: Section<UIView>?
        if subscription.plan == .plus, ServicePlanDataService.currentSubscription?.plan == subscription.plan {
            buyLink = ServiceLevelDataFactory.makeBuyLinkSection()
        }
        self.plan = subscription.plan
        self.details = subscription.details
        self.sections =  [ServiceLevelDataFactory.makeLogoSection(plan: subscription.plan),
                          ServiceLevelDataFactory.makeCapabilitiesSection(plan: subscription.plan, details: subscription.details),
                          ServiceLevelDataFactory.makePlanStatusSection(plan: subscription.plan, details: subscription.details),
                          buyLink,
                          ServiceLevelDataFactory.makeSectionHeader("OTHER SERVICE PLANS"),
                          ServiceLevelDataFactory.makeLinksSection(except: subscription.plan)].compactMap { $0 }
    }
}
