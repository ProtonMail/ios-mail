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
}

class CurrentPlanViewModel: ServiceLevelViewModel {
    let cellTypes: [UICollectionViewCell.Type] = [ConfigurableCell.self]
    let accessoryTypes: [UICollectionReusableView.Type] = [Separator.self]
    
    let title = LocalString._menu_service_plan_title
    private lazy var currentPlan: ServicePlan? = ServicePlanDataService.currentServicePlan
    private lazy var details: ServicePlanDetails? = ServicePlanDataService.currentServicePlan?.fetchDetails()
    
    lazy var sections: [Section<UIView>] = {
        return [self.makeHeader(),
                self.makeCapabilities(),
                self.makeFooter(),
                self.makeLinks()].compactMap { $0 }
    }()
    
    lazy var collectionViewLayout: UICollectionViewLayout = TableLayout()
    
    private func makeHeader() -> Section<UIView>? {
        guard let currentPlan = self.currentPlan else { return nil }
        let image = UIImage(named: "Logo")?.withRenderingMode(.alwaysTemplate)
        let headerView = ServicePlanHeader(image: image, title: currentPlan.headerText, subicon: currentPlan.subheader)
        return Section(elements: [headerView], cellType: ConfigurableCell.self)
    }
    typealias SPC = ServicePlanCapability
    private func makeCapabilities() -> Section<UIView>? {
        guard let details = self.details else {
            return nil
        }
        
        let multiuser1 = on([.pro], put: SPC(image: UIImage(named:"iap_users"),
                                             title: "Unlimited messages sent/day"))
        
        let multiuser2 = on([.visionary], put: SPC(image: UIImage(named:"iap_users"),
                                                   title: "Up to \(details.maxMembers) users"))
        
        let emailAddresses = SPC(image: UIImage(named: "iap_email"),
                                 title: "\(details.maxAddresses) email addresses")
        
        let storage = SPC(image: UIImage(named: "iap_hdd"),
                          title: "\(details.maxSpace) storage capacity")
        
        let messageLimit = on([.free], put: SPC(image: UIImage(named: "iap_lock"),
                                                title: "Limited to \(details.amount) messages sent/day"))
        
        let bridge = on([.plus, .pro, .visionary], put: SPC(image: UIImage(named: "iap_link"),
                                                            title: "IMAP/SMTP Support via ProtonMail Bridge"))
        
        let labels = on([.plus, .pro, .visionary], put: SPC(image: UIImage(named: "iap_folder"),
                                                            title: "Lables, Folders, Filters & More"))
        
        let support = on([.pro, .visionary], put: SPC(image: UIImage(named: "iap_lifering"),
                                                      title: "Support for \(details.maxDomains) custom domains (e.g. user@yourdomain.com)"))
        
        let vpn = on([.visionary], put: SPC(image: UIImage(),
                                            title: "ProtonVPN included"))
        
        let capabilities = [multiuser1, multiuser2, emailAddresses, storage, messageLimit, bridge, labels, support, vpn].compactMap { $0 }
        return Section(elements: capabilities, cellType: ConfigurableCell.self)
    }
    
    private func makeFooter() -> Section<UIView>? {
        guard let currentPlan = self.currentPlan, let details = self.details else { return nil }
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
    
    private func makeLinks() -> Section<UIView>? {
        // FIXME: colored attributed strings
        // FIXME: how to inject drilldown here?
        let title = TableSectionHeader(title: "OTHER SERVICE PLANS")
        let link1 = on([.plus, .pro, .visionary], put: ServicePlanCapability(title: "ProtonMail Free", serviceIconVisible: true))
        let link2 = on([.free, .pro, .visionary], put: ServicePlanCapability(title: "ProtonMail Plus", serviceIconVisible: true))
        let link3 = on([.free, .plus, .visionary], put: ServicePlanCapability(title: "ProtonMail Pro", serviceIconVisible: true))
        let link4 = on([.free, .plus, .pro], put: ServicePlanCapability(title: "ProtonMail Visionary", serviceIconVisible: true))
        
        return Section(elements: [title, link1, link2, link3, link4].compactMap { $0 }, cellType: ConfigurableCell.self)
    }
    
}

extension CurrentPlanViewModel {
    private func on(_ plans: [ServicePlan], put view: UIView) -> UIView? {
        return plans.contains(self.currentPlan) ? view : nil
    }
}
