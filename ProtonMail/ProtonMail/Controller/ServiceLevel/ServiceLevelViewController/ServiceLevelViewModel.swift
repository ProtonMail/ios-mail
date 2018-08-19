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
    func setup(with plan: ServicePlan?)
}

class PlanDetailsViewModel: PlanAndLinksViewModel {
    override func setup(with plan: ServicePlan?) {
        self.plan = plan
        self.details = plan?.fetchDetails()
        self.sections = [self.makeHeader(),
                         self.makeCapabilities(),
                         self.makeFooter()].compactMap { $0 }
    }
}

class PlanAndLinksViewModel: ServiceLevelViewModel {
    let cellTypes: [UICollectionViewCell.Type] = [ConfigurableCell.self]
    let accessoryTypes: [UICollectionReusableView.Type] = [Separator.self]
    
    let title = LocalString._menu_service_plan_title
    fileprivate var plan: ServicePlan?
    fileprivate var details: ServicePlanDetails?
    internal var sections: [Section<UIView>] = []
    
    internal func setup(with plan: ServicePlan?) {
        self.plan = plan
        self.details = plan?.fetchDetails()
        self.sections =  [self.makeHeader(),
                          self.makeCapabilities(),
                          self.makeFooter(),
                          self.makeLinks()].compactMap { $0 }
    }
    lazy var collectionViewLayout: UICollectionViewLayout = TableLayout()
    
    fileprivate func makeHeader() -> Section<UIView>? {
        guard let currentPlan = self.plan else { return nil }
        let image = UIImage(named: "Logo")?.withRenderingMode(.alwaysTemplate)
        let headerView = ServicePlanHeader(image: image, title: currentPlan.headerText, subicon: currentPlan.subheader)
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
                     put: SPC(image: UIImage(),
                              title: .init(string: "ProtonVPN included")))
        
        let capabilities = [multiuser1, multiuser2, emailAddresses, storage, messageLimit, bridge, labels, support, vpn].compactMap { $0 }
        return Section(elements: capabilities, cellType: ConfigurableCell.self)
    }
    
    fileprivate func makeFooter() -> Section<UIView>? {
        guard let currentPlan = self.plan, let details = self.details else { return nil }
        var message: String = ""
        switch currentPlan { // FIXME: check also if it was purchased via Apple
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
    
    internal func shouldPerformSegue(byItemOn indexPath: IndexPath) -> ServiceLevelCoordinator.Destination? {
        guard let element = self.sections[indexPath.section].elements[indexPath.item] as? ServicePlanCapability else { return nil }
        return element.context as? ServiceLevelCoordinator.Destination
    }
}

extension PlanAndLinksViewModel {
    private func on(_ plans: [ServicePlan], put view: UIView) -> UIView? {
        return plans.contains(self.plan) ? view : nil
    }
}
