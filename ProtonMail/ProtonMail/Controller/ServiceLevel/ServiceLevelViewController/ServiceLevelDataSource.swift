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
    internal var sections: [Section<UIView>] = []
    
    init(delegate: ServiceLevelDataSourceDelegate, subscription: Subscription!) {
        self.delegate = delegate
        self.setup(with: subscription)
    }
    
    private func setup(with subscription: Subscription) {
        self.sections = [ServiceLevelDataFactory.makeCurrentPlanStatusSection(subscription: subscription),
                         ServiceLevelDataFactory.makeBuyButtonSection(plan: subscription.plan, delegate: self.delegate),
                         ServiceLevelDataFactory.makeAcknowladgementsSection()].compactMap { $0 }
    }
}

class PlanDetailsDataSource: ServiceLevelDataSource {
    weak var delegate: ServiceLevelDataSourceDelegate!
    internal var sections: [Section<UIView>] = []
    internal var title: String
    
    init(delegate: ServiceLevelDataSourceDelegate, plan: ServicePlan) {
        self.delegate = delegate
        self.title = "Get " + plan.subheader.0
        guard let details = plan.fetchDetails() else {
            return
        }
        self.setup(with: plan, details: details)
    }
    
    private func setup(with plan: ServicePlan, details: ServicePlanDetails) {
        var capabilities: Section<UIView>?
        var footer: Section<UIView>?
        var acknowladgements: Section<UIView>?
        if let details = plan.fetchDetails() {
            capabilities = ServiceLevelDataFactory.makeCapabilitiesSection(plan: plan, details: details)
            if plan == .plus, ServicePlanDataService.currentSubscription?.plan == .free {
                footer = ServiceLevelDataFactory.makeBuyButtonSection(plan: plan, delegate: self.delegate)
                acknowladgements = ServiceLevelDataFactory.makeAcknowladgementsSection()
            } else {
                footer = ServiceLevelDataFactory.makeUnavailablePlanStatusSection(plan: plan)
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
    internal var sections: [Section<UIView>] = []
    let title = LocalString._menu_service_plan_title
    
    init(delegate: ServiceLevelDataSourceDelegate, subscription: Subscription?) {
        self.delegate = delegate
        guard let subscription = subscription else {
            self.sections = [ServiceLevelDataFactory.makeLinksSection()]
            return
        }
        self.setup(with: subscription)
    }
    
    private func setup(with subscription: Subscription) {
        var buyLink: Section<UIView>?
        if let currentSubscription = ServicePlanDataService.currentSubscription,
            subscription.plan == .plus, // Plus description opened
            currentSubscription.plan == subscription.plan, // currently subscribed to Plus
            !currentSubscription.hadOnlinePayments, // did pay only via apple
            currentSubscription.end?.compare(Date()) == .orderedAscending //  subscrition is expired
        {
            buyLink = ServiceLevelDataFactory.makeBuyLinkSection()
        }
        self.sections =  [ServiceLevelDataFactory.makeLogoSection(plan: subscription.plan),
                          ServiceLevelDataFactory.makeCapabilitiesSection(plan: subscription.plan, details: subscription.details),
                          ServiceLevelDataFactory.makeCurrentPlanStatusSection(subscription: subscription),
                          buyLink,
                          ServiceLevelDataFactory.makeSectionHeader("OTHER SERVICE PLANS"),
                          ServiceLevelDataFactory.makeLinksSection(except: subscription.plan)].compactMap { $0 }
    }
}
