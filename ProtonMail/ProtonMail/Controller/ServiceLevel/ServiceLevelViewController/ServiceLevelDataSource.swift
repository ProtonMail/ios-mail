//
//  ServiceLevelViewModel.swift
//  ProtonMail - Created on 12/08/2018.
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


import UIKit

protocol ServiceLevelDataSource {
    var delegate: ServiceLevelDataSourceDelegate! { get set }
    var title: String { get }
    var sections: [Section<UIView>] { get }
    func shouldPerformSegue(byItemOn: IndexPath) -> ServiceLevelCoordinator.Destination?
    func reload()
}

extension ServiceLevelDataSource {
    internal func shouldPerformSegue(byItemOn indexPath: IndexPath) -> ServiceLevelCoordinator.Destination? {
        guard let element = self.sections[indexPath.section].elements[indexPath.item] as? ServicePlanCapability else { return nil }
        return element.context as? ServiceLevelCoordinator.Destination
    }
}

class BuyMoreDataSource: ServiceLevelDataSource {
    weak var delegate: ServiceLevelDataSourceDelegate!
    internal let title = LocalString._more_credits
    internal var sections: [Section<UIView>] = []
    private var subscription: Subscription
    
    internal func reload() {
        self.setup(with: self.subscription)
    }
    
    init(delegate: ServiceLevelDataSourceDelegate, subscription: Subscription!) {
        self.delegate = delegate
        self.subscription = subscription
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
    
    private var plan: ServicePlan
    
    internal func reload() {
        if let details = plan.fetchDetails() {
            self.setup(with: self.plan, details: details)
        }
    }
    
    init(delegate: ServiceLevelDataSourceDelegate, plan: ServicePlan) {
        self.delegate = delegate
        self.title = String(format: LocalString._get_plan, plan.subheader.0)
        self.plan = plan
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
            if plan == .plus, ServicePlanDataService.shared.currentSubscription?.plan == .free {
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
    internal let title = LocalString._menu_service_plan_title
    private var subscription: Subscription?
    
    internal func reload() {
        if let subscription = subscription {
            self.setup(with: subscription)
        }
    }
    
    init(delegate: ServiceLevelDataSourceDelegate, subscription: Subscription?) {
        self.delegate = delegate
        guard let subscription = subscription else {
            self.sections = [ServiceLevelDataFactory.makeLinksSection()]
            return
        }
        self.subscription = subscription
        self.setup(with: subscription)
    }
    
    private func setup(with subscription: Subscription) {
        var buyLink: Section<UIView>?
        if let currentSubscription = ServicePlanDataService.shared.currentSubscription,
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
                          ServiceLevelDataFactory.makeSectionHeader(LocalString._other_plans),
                          ServiceLevelDataFactory.makeLinksSection(except: subscription.plan)].compactMap { $0 }
    }
}
