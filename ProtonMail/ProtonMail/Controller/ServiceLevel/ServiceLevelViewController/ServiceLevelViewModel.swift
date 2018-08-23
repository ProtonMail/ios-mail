//
//  ServiceLevelViewModel.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 12/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

protocol ServiceLevelViewModel {
    var title: String { get }
    var collectionViewLayout: UICollectionViewLayout { get }
    var sections: [Section<UIView>] { get }
    var cellTypes: [UICollectionViewCell.Type] { get }
    var accessoryTypes: [UICollectionReusableView.Type] { get }
    func shouldPerformSegue(byItemOn: IndexPath) -> ServiceLevelCoordinator.Destination?
}

infix operator ~
fileprivate func ~(_ right: ServicePlan, _ left: (Array<ServicePlan>, UIView)) -> UIView? {
    return left.0.contains(right) ? left.1 : nil
}

extension ServiceLevelViewModel {
    fileprivate func makeLogoSection(plan: ServicePlan) -> Section<UIView> {
        let image = UIImage(named: "Logo")?.withRenderingMode(.alwaysTemplate)
        let headerView = ServicePlanHeader(image: image, title: plan.headerText, subicon: plan.subheader)
        return Section(elements: [headerView], cellType: AutoLayoutSizedCell.self)
    }
    
    typealias SPC = ServicePlanCapability
    fileprivate func makeCapabilitiesSection(plan: ServicePlan, details: ServicePlanDetails) -> Section<UIView> {
        let multiuser1 = plan ~ ([.pro], SPC(image: UIImage(named:"iap_users"),
                                             title: .init(string: "Unlimited messages sent/day")))
        
        let multiuser2 = plan ~ ([.visionary], SPC(image: UIImage(named:"iap_users"),
                                                   title: .init(string: "Up to \(details.maxMembers) users")))
        
        let emailAddresses = SPC(image: UIImage(named: "iap_email"),
                                 title: .init(string: "\(details.maxAddresses) email addresses"))
        
        let storage = SPC(image: UIImage(named: "iap_hdd"),
                          title: .init(string: "\(details.maxSpace) storage capacity"))
        
        let messageLimit = plan ~ ([.free], SPC(image: UIImage(named: "iap_lock"),
                                                title: .init(string: "Limited to \(details.amount) messages sent/day")))
        
        let bridge = plan ~ ([.plus, .pro, .visionary], SPC(image: UIImage(named: "iap_link"),
                                                            title: .init(string: "IMAP/SMTP Support via ProtonMail Bridge")))
        
        let labels = plan ~ ([.plus, .pro, .visionary], SPC(image: UIImage(named: "iap_folder"),
                                                            title: .init(string: "Lables, Folders, Filters & More")))
        
        let support = plan ~ ([.pro, .visionary], SPC(image: UIImage(named: "iap_lifering"),
                                                      title: .init(string: "Support for \(details.maxDomains) custom domains (e.g. user@yourdomain.com)")))
        
        let vpn = plan ~ ([.visionary], SPC(image: UIImage(named: "iap_vpn"),
                                            title: .init(string: "ProtonVPN included")))
        
        let capabilities = [multiuser1, multiuser2, emailAddresses, storage, messageLimit, bridge, labels, support, vpn, UIView()].compactMap { $0 }
        return Section(elements: capabilities, cellType: AutoLayoutSizedCell.self)
    }
    
    fileprivate func makePlanStatusSection(plan: ServicePlan, details: ServicePlanDetails) -> Section<UIView> {
        var message: String = ""
        switch plan { // FIXME: check also if it was purchased via Apple
        case .free:
            message = "Upgrade to a paid plan to benefit from more features"
        case .plus, .pro, .visionary:
            message = "Your plan is currently active until \(details.cycle)" // FIXME: due time?
        }
        let footerView = ServicePlanFooter(title: message)
        
        return Section(elements: [footerView], cellType: AutoLayoutSizedCell.self)
    }
    
    fileprivate func makeLinksSection(except currentPlan: ServicePlan? = nil) -> Section<UIView> {
        let links: [UIView] = [ServicePlan.free, ServicePlan.plus, ServicePlan.pro, ServicePlan.visionary].compactMap { plan in
            guard plan != currentPlan else {
                return nil
            }
            
            let titleColored = NSAttributedString(string: plan.subheader.0.uppercased(),
                                                  attributes: [.foregroundColor : plan.subheader.1])
            let attributed = NSMutableAttributedString(string: "ProtonMail ")
            attributed.append(titleColored)
            return ServicePlanCapability(title: attributed,
                                         serviceIconVisible: true,
                                         context: ServiceLevelCoordinator.Destination.details(of: plan))
        }

        return Section(elements: links, cellType: AutoLayoutSizedCell.self)
    }
    
    fileprivate func makeSectionHeader(_ text: String) -> Section<UIView> {
        return Section(elements: [TableSectionHeader(title: text)], cellType: FirstSubviewSizedCell.self)
    }
    
    fileprivate func makeBuyLinkSection() -> Section<UIView>? {
        let blank = TableSectionHeader(title: "")
        let buyMore = ServicePlanCapability(title: NSAttributedString(string: "Buy More Credits"), serviceIconVisible: true, context: ServiceLevelCoordinator.Destination.buyMore)
        return Section(elements: [blank, buyMore], cellType: AutoLayoutSizedCell.self)
    }
    
    fileprivate func makeBuyButtonSection(plan: ServicePlan) -> Section<UIView>? {
        guard let productId = plan.storeKitProductId,
            let price = StoreKitManager.default.priceLabelForProduct(id: productId) else
        {
            return nil
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = price.1
        guard let priceString = formatter.string(from: price.0),
            let originalPriceString = formatter.string(from: NSNumber(value: Double(truncating: price.0) * 0.75)),
            let feeString = formatter.string(from: NSNumber(value: Double(truncating: price.0) * 0.25)) else
        {
            return nil
        }
        
        let title = NSMutableAttributedString(string: priceString,
                                              attributes: [.font: UIFont.preferredFont(forTextStyle: .title1),
                                                           .foregroundColor: UIColor.white])
        let caption = NSAttributedString(string: "\nfor one year",
                                         attributes: [.font: UIFont.preferredFont(forTextStyle: .body),
                                                      .foregroundColor: UIColor.white])
        title.append(caption)
        let subtitle = originalPriceString + " ProtonMail Plus +\n " + feeString + " Apple in-app purchase fee"
        let footerView = ServicePlanFooter(subTitle: subtitle,
                                           buttonTitle: title,
                                           buttonEnabled: StoreKitManager.default.readyToPurchaseProduct(id: productId, username: sharedUserDataService.username!)) { button in
            // FIXME: change availability of button to exclude double tap
            try! StoreKitManager.default.purchaseProduct(withId: productId, username: sharedUserDataService.username!) // FIXME: username
        }
        return Section(elements: [footerView], cellType: AutoLayoutSizedCell.self)
    }
    
    fileprivate func makeAcknowladgementsSection() -> Section<UIView> {
        let message = """
        var collectionViewLayout: UICollectionViewLayout = TableLayout()
        let cellTypes: [UICollectionViewCell.Type] = [ConfigurableCell.self]
        let accessoryTypes: [UICollectionReusableView.Type] = [Separator.self]
        let title = LocalString._menu_service_plan_title
        var plan: ServicePlan?
        var details: ServicePlanDetails?
        internal var sections: [Section<UIView>] = []
        """
        return Section(elements: [TableSectionHeader(title: message)], cellType: FirstSubviewSizedCell.self)
    }
    
    internal func shouldPerformSegue(byItemOn indexPath: IndexPath) -> ServiceLevelCoordinator.Destination? {
        guard let element = self.sections[indexPath.section].elements[indexPath.item] as? ServicePlanCapability else { return nil }
        return element.context as? ServiceLevelCoordinator.Destination
    }
}

class BuyMoreViewModel: ServiceLevelViewModel {
    var collectionViewLayout: UICollectionViewLayout = TableLayout()
    let cellTypes: [UICollectionViewCell.Type] = [AutoLayoutSizedCell.self, FirstSubviewSizedCell.self]
    let accessoryTypes: [UICollectionReusableView.Type] = [SeparatorDecorationView.self]
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
        self.sections = [self.makePlanStatusSection(plan: subscription.plan, details: subscription.details),
                         self.makeBuyButtonSection(plan: subscription.plan),
                         self.makeAcknowladgementsSection()].compactMap { $0 }
    }
}

class PlanDetailsViewModel: ServiceLevelViewModel {
    var collectionViewLayout: UICollectionViewLayout = TableLayout()
    
    let cellTypes: [UICollectionViewCell.Type] = [AutoLayoutSizedCell.self, FirstSubviewSizedCell.self]
    let accessoryTypes: [UICollectionReusableView.Type] = [SeparatorDecorationView.self]
    
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
            capabilities = self.makeCapabilitiesSection(plan: plan, details: details)
            if plan == .plus, ServicePlanDataService.currentSubscription?.plan == .free {
                footer = self.makeBuyButtonSection(plan: plan)
                acknowladgements = self.makeAcknowladgementsSection()
            } else {
                footer = self.makePlanStatusSection(plan: plan, details: details)
            }
        }
        self.sections = [self.makeLogoSection(plan: plan),
                         capabilities,
                         footer,
                         acknowladgements].compactMap { $0 }
    }
}

class PlanAndLinksViewModel: ServiceLevelViewModel {
    let cellTypes: [UICollectionViewCell.Type] = [AutoLayoutSizedCell.self, FirstSubviewSizedCell.self]
    let accessoryTypes: [UICollectionReusableView.Type] = [SeparatorDecorationView.self]
    
    let title = LocalString._menu_service_plan_title
    var plan: ServicePlan?
    var details: ServicePlanDetails?
    internal var sections: [Section<UIView>] = []

    internal func setup(with subscription: Subscription?) {
        guard let subscription = subscription else {
            self.sections = [self.makeLinksSection()]
            return
        }
        var buyLink: Section<UIView>?
        if subscription.plan == .plus, ServicePlanDataService.currentSubscription?.plan == subscription.plan {
            buyLink = self.makeBuyLinkSection()
        }
        self.plan = subscription.plan
        self.details = subscription.details
        self.sections =  [self.makeLogoSection(plan: subscription.plan),
                          self.makeCapabilitiesSection(plan: subscription.plan, details: subscription.details),
                          self.makePlanStatusSection(plan: subscription.plan, details: subscription.details),
                          buyLink,
                          self.makeSectionHeader("OTHER SERVICE PLANS"),
                          self.makeLinksSection(except: subscription.plan)].compactMap { $0 }
    }
    lazy var collectionViewLayout: UICollectionViewLayout = TableLayout()
}
