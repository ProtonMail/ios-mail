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
    
    var plan: ServicePlan? { get set }
    var details: ServicePlanDetails? { get set }
}
extension ServiceLevelViewModel {
    fileprivate func makeHeader() -> Section<UIView>? {
        guard let plan = self.plan else { return nil }
        let image = UIImage(named: "Logo")?.withRenderingMode(.alwaysTemplate)
        let headerView = ServicePlanHeader(image: image, title: plan.headerText, subicon: plan.subheader)
        return Section(elements: [headerView], cellType: ConfigurableCell.self)
    }
    
    typealias SPC = ServicePlanCapability
    fileprivate func makeCapabilities() -> Section<UIView>? {
        guard let details = self.details else {
            return nil
        }
        
        let multiuser1 = on([.pro],
                            put: SPC(image: UIImage(named:"iap_users"),
                                     title: .init(string: "Unlimited messages sent/day")))
        
        let multiuser2 = on([.visionary],
                            put: SPC(image: UIImage(named:"iap_users"),
                                     title: .init(string: "Up to \(details.maxMembers) users")))
        
        let emailAddresses = SPC(image: UIImage(named: "iap_email"),
                                 title: .init(string: "\(details.maxAddresses) email addresses"))
        
        let storage = SPC(image: UIImage(named: "iap_hdd"),
                          title: .init(string: "\(details.maxSpace) storage capacity"))
        
        let messageLimit = on([.free],
                              put: SPC(image: UIImage(named: "iap_lock"),
                                       title: .init(string: "Limited to \(details.amount) messages sent/day")))
        
        let bridge = on([.plus, .pro, .visionary],
                        put: SPC(image: UIImage(named: "iap_link"),
                                 title: .init(string: "IMAP/SMTP Support via ProtonMail Bridge")))
        
        let labels = on([.plus, .pro, .visionary],
                        put: SPC(image: UIImage(named: "iap_folder"),
                                 title: .init(string: "Lables, Folders, Filters & More")))
        
        let support = on([.pro, .visionary],
                         put: SPC(image: UIImage(named: "iap_lifering"),
                                  title: .init(string: "Support for \(details.maxDomains) custom domains (e.g. user@yourdomain.com)")))
        
        let vpn = on([.visionary],
                     put: SPC(image: UIImage(named: "iap_vpn"),
                              title: .init(string: "ProtonVPN included")))
        
        let capabilities = [multiuser1, multiuser2, emailAddresses, storage, messageLimit, bridge, labels, support, vpn, UIView()].compactMap { $0 }
        return Section(elements: capabilities, cellType: ConfigurableCell.self)
    }
    
    fileprivate func makeFooter() -> Section<UIView>? {
        guard let plan = self.plan, let details = self.details else { return nil }
        var message: String = ""
        switch plan { // FIXME: check also if it was purchased via Apple
        case .free:
            message = "Upgrade to a paid plan to benefit from more features"
        case .plus, .pro, .visionary:
            message = "Your plan is currently active until \(details.cycle)" // FIXME: due time?
        }
        let footerView = ServicePlanFooter(title: message)
        
        return Section(elements: [footerView], cellType: ConfigurableCell.self)
    }
    
    fileprivate func makeLinks() -> Section<UIView>? {
        var links: [UIView] = [ServicePlan.free, ServicePlan.plus, ServicePlan.pro, ServicePlan.visionary].compactMap { plan in
            guard plan != self.plan else {
                return nil
            }
            
            let titleColored = NSAttributedString(string: plan.subheader.0, attributes: [.foregroundColor : plan.subheader.1])
            let attributed = NSMutableAttributedString(string: "ProtonMail ")
            attributed.append(titleColored)
            return ServicePlanCapability(title: attributed,
                                         serviceIconVisible: true,
                                         context: ServiceLevelCoordinator.Destination.details(of: plan))
        }
        
        links.insert(TableSectionHeader(title: "OTHER SERVICE PLANS"), at: 0)
        
        return Section(elements: links, cellType: ConfigurableCell.self)
    }
    
    fileprivate func makeBuyMore() -> Section<UIView>? {
        guard let plan = self.plan,
            plan == .plus,
            ServicePlanDataService.currentSubscription?.plan == plan else
        {
            return nil
        }
        let blank = TableSectionHeader(title: "")
        let buyMore = ServicePlanCapability(title: NSAttributedString(string: "Buy More Credits"), serviceIconVisible: true, context: ServiceLevelCoordinator.Destination.buyMore)
        return Section(elements: [blank, buyMore], cellType: ConfigurableCell.self)
    }
    
    fileprivate func makeFooterWithButton() -> Section<UIView>? {
        let price = NSMutableAttributedString(string: "$69.99",
                                              attributes: [.font: UIFont.preferredFont(forTextStyle: .title1),
                                                           .foregroundColor: UIColor.white])
        let caption = NSAttributedString(string: "\nfor one year", attributes: [.font: UIFont.preferredFont(forTextStyle: .body),
                                                                                .foregroundColor: UIColor.white])
        price.append(caption)
        let footerView = ServicePlanFooter(subTitle: "$48 ProtonMail Plus +\n $21.99 Apple in-app purchase fee",
                                           buttonTitle: price)
        
        // FIXME: put acknowledgement text here
        return Section(elements: [footerView], cellType: ConfigurableCell.self)
    }
    
    internal func shouldPerformSegue(byItemOn indexPath: IndexPath) -> ServiceLevelCoordinator.Destination? {
        guard let element = self.sections[indexPath.section].elements[indexPath.item] as? ServicePlanCapability else { return nil }
        return element.context as? ServiceLevelCoordinator.Destination
    }
}

class BuyMoreViewModel: ServiceLevelViewModel {
    var collectionViewLayout: UICollectionViewLayout = TableLayout()
    let cellTypes: [UICollectionViewCell.Type] = [ConfigurableCell.self]
    let accessoryTypes: [UICollectionReusableView.Type] = [Separator.self]
    let title = LocalString._menu_service_plan_title
    var plan: ServicePlan?
    var details: ServicePlanDetails?
    internal var sections: [Section<UIView>] = []
    
    func setup(with plan: ServicePlan?) {
        self.plan = plan
        self.details = plan?.fetchDetails()
        self.sections = [self.makeFooter(), self.makeFooterWithButton()].compactMap { $0 }
    }
    
    func setup(with subscription: Subscription?) {
        self.plan = subscription?.plan
        self.details = subscription?.details
        self.sections = [self.makeFooter(), self.makeFooterWithButton()].compactMap { $0 }
    }
}

class PlanDetailsViewModel: ServiceLevelViewModel {
    var collectionViewLayout: UICollectionViewLayout = TableLayout()
    
    let cellTypes: [UICollectionViewCell.Type] = [ConfigurableCell.self]
    let accessoryTypes: [UICollectionReusableView.Type] = [Separator.self]
    
    let title = LocalString._menu_service_plan_title
    var plan: ServicePlan?
    var details: ServicePlanDetails?
    internal var sections: [Section<UIView>] = []
    
    func setup(with plan: ServicePlan?) {
        self.plan = plan
        self.details = plan?.fetchDetails()
        self.sections = [self.makeHeader(),
                         self.makeCapabilities(),
                         self.makeSimpleFooter()].compactMap { $0 }
    }
    
    fileprivate func makeSimpleFooter() -> Section<UIView>? {
        guard let plan = self.plan,
            plan == .plus,
            ServicePlanDataService.currentSubscription?.plan == .free else
        {
            return self.makeFooter()
        }
        return self.makeFooterWithButton()
    }
}

class PlanAndLinksViewModel: ServiceLevelViewModel {
    let cellTypes: [UICollectionViewCell.Type] = [ConfigurableCell.self]
    let accessoryTypes: [UICollectionReusableView.Type] = [Separator.self]
    
    let title = LocalString._menu_service_plan_title
    var plan: ServicePlan?
    var details: ServicePlanDetails?
    internal var sections: [Section<UIView>] = []

    internal func setup(with subscription: Subscription?) {
        self.plan = subscription?.plan
        self.details = subscription?.details
        self.sections =  [self.makeHeader(),
                          self.makeCapabilities(),
                          self.makeFooter(),
                          self.makeBuyMore(),
                          self.makeLinks()].compactMap { $0 }
    }
    lazy var collectionViewLayout: UICollectionViewLayout = TableLayout()
}

extension ServiceLevelViewModel {
    private func on(_ plans: [ServicePlan], put view: UIView) -> UIView? {
        return plans.contains(self.plan) ? view : nil
    }
}
