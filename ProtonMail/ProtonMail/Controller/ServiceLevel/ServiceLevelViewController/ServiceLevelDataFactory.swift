//
//  ServiceLevelDataFactory.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 23/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

enum ServiceLevelDataFactory {
    internal static func makeLogoSection(plan: ServicePlan) -> Section<UIView> {
        let image = UIImage(named: "Logo")?.withRenderingMode(.alwaysTemplate)
        let headerView = ServicePlanHeader(image: image, title: plan.headerText, subicon: plan.subheader)
        return Section(elements: [headerView], cellType: AutoLayoutSizedCell.self)
    }
    
    typealias SPC = ServicePlanCapability
    internal static func makeCapabilitiesSection(plan: ServicePlan, details: ServicePlanDetails) -> Section<UIView> {
        var body = [NSAttributedStringKey: Any]()
        body[.font] = UIFont.preferredFont(forTextStyle: .body)
        
        let multiuser1 = plan ~ ([.pro], SPC(image: UIImage(named:"iap_users"),
                                             title: .init(string: "Unlimited messages sent/day", attributes: body)))
        
        let multiuser2 = plan ~ ([.visionary], SPC(image: UIImage(named:"iap_users"),
                                                   title: .init(string: "Up to \(details.maxMembers) users", attributes: body)))
        
        let emailAddresses = SPC(image: UIImage(named: "iap_email"),
                                 title: .init(string: "\(details.maxAddresses) email addresses", attributes: body))
        
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        let storageString = formatter.string(fromByteCount: Int64(details.maxSpace)) + " storage capacity"
        let storage = SPC(image: UIImage(named: "iap_hdd"), title: .init(string: storageString, attributes: body))
        
        let messageLimit = plan ~ ([.free], SPC(image: UIImage(named: "iap_lock"),
                                                title: .init(string: "Limited to \(details.amount) messages sent/day", attributes: body)))
        
        let bridge = plan ~ ([.plus, .pro, .visionary], SPC(image: UIImage(named: "iap_link"),
                                                            title: .init(string: "IMAP/SMTP Support via ProtonMail Bridge", attributes: body)))
        
        let labels = plan ~ ([.plus, .pro, .visionary], SPC(image: UIImage(named: "iap_folder"),
                                                            title: .init(string: "Lables, Folders, Filters & More", attributes: body)))
        
        let support = plan ~ ([.pro, .visionary], SPC(image: UIImage(named: "iap_lifering"),
                                                      title: .init(string: "Support for \(details.maxDomains) custom domains (e.g. user@yourdomain.com)", attributes: body)))
        
        let vpn = plan ~ ([.visionary], SPC(image: UIImage(named: "iap_vpn"),
                                            title: .init(string: "ProtonVPN included", attributes: body)))
        
        let capabilities = [multiuser1, multiuser2, emailAddresses, storage, messageLimit, bridge, labels, support, vpn].compactMap { $0 }
        return Section(elements: capabilities, cellType: FirstSubviewSizedCell.self)
    }
    
    internal static func makeUnavailablePlanStatusSection(plan: ServicePlan) -> Section<UIView> {
        var regularAttributes = [NSAttributedStringKey: Any]()
        regularAttributes[.font] = UIFont.preferredFont(forTextStyle: .body)
        var coloredAttributes = regularAttributes
        coloredAttributes[.foregroundColor] = plan.subheader.1
        
        let title1 = NSMutableAttributedString(string: "To migrate to ", attributes: regularAttributes)
        let title2 = NSMutableAttributedString(string: plan.subheader.0, attributes: coloredAttributes)
        let title3 = NSMutableAttributedString(string: ", you have to login to our website and make the necessary adjustments to comply with the plan's requirements ", attributes: regularAttributes)
        
        title1.append(title2)
        title1.append(title3)
        let footerView = ServicePlanFooter(title: title1)
        
        return Section(elements: [footerView], cellType: AutoLayoutSizedCell.self)
    }
    
    internal static func makeCurrentPlanStatusSection(subscription: Subscription) -> Section<UIView> {
        var message: NSAttributedString!
        var regularAttributes = [NSAttributedStringKey: Any]()
        regularAttributes[.font] = UIFont.preferredFont(forTextStyle: .body)
        var coloredAttributes = regularAttributes
        coloredAttributes[.foregroundColor] = subscription.plan.subheader.1
        
        switch subscription.plan { // FIXME: check also if it was purchased via Apple
        case .free:
            message = NSAttributedString(string: "Upgrade to a paid plan to benefit from more features", attributes: regularAttributes)
        case .plus, .pro, .visionary:
            let formatter = DateFormatter()
            formatter.timeStyle = .none
            formatter.dateStyle = .short
            
            if let end = subscription.end {
                let title0 = subscription.hadOnlinePayments ? "Your plan will automatically renew on " : "Your plan is currently active until "
                let title1 = NSMutableAttributedString(string: title0, attributes: regularAttributes)
                let title2 = NSAttributedString(string: formatter.string(from: end), attributes: coloredAttributes)
                title1.append(title2)
                message = title1
            }
        }
        let footerView = ServicePlanFooter(title: message)
        
        return Section(elements: [footerView], cellType: AutoLayoutSizedCell.self)
    }
    
    internal static func makeLinksSection(except currentPlan: ServicePlan? = nil) -> Section<UIView> {
        let links: [UIView] = [ServicePlan.free, ServicePlan.plus, ServicePlan.pro, ServicePlan.visionary].compactMap { plan in
            guard plan != currentPlan else {
                return nil
            }
            let titleColored = NSAttributedString(string: plan.subheader.0.uppercased(),
                                                  attributes: [.foregroundColor : UIColor.ProtonMail.ButtonBackground,
                                                               .font: UIFont.preferredFont(forTextStyle: .body)])
            var body = [NSAttributedStringKey: Any]()
            body[.font] = UIFont.preferredFont(forTextStyle: .body)
            let attributed = NSMutableAttributedString(string: "ProtonMail ", attributes: body)
            attributed.append(titleColored)
            return ServicePlanCapability(title: attributed, serviceIconVisible: true, context: ServiceLevelCoordinator.Destination.details(of: plan))
        }
        
        return Section(elements: links, cellType: FirstSubviewSizedCell.self)
    }
    
    internal static func makeSectionHeader(_ text: String) -> Section<UIView> {
        return Section(elements: [TableSectionHeader(title: text)], cellType: FirstSubviewSizedCell.self)
    }
    
    internal static func makeBuyLinkSection() -> Section<UIView>? {
        var body = [NSAttributedStringKey: Any]()
        body[.font] = UIFont.preferredFont(forTextStyle: .body)
        let blank = TableSectionHeader(title: " ")
        let buyMore = ServicePlanCapability(title: NSAttributedString(string: "Buy More Credits", attributes: body), serviceIconVisible: true, context: ServiceLevelCoordinator.Destination.buyMore)
        return Section(elements: [blank, buyMore], cellType: FirstSubviewSizedCell.self)
    }
    
    internal static func makeBuyButtonSection(plan: ServicePlan,
                                                 delegate: ServiceLevelDataSourceDelegate) -> Section<UIView>?
    {
        guard let productId = plan.storeKitProductId,
            let price = StoreKitManager.default.priceLabelForProduct(id: productId) else
        {
            let noStoreFooter = ServicePlanFooter(subTitle: "Could not connect to Store. Please, try later.")
            return Section(elements: [noStoreFooter], cellType: AutoLayoutSizedCell.self)
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
                                           buttonEnabled: delegate.canPurchaseProduct(id: productId)) { button in
                                            // FIXME: change availability of button to exclude double tap
                                            delegate.purchaseProduct(id: productId)
        }
        return Section(elements: [footerView], cellType: AutoLayoutSizedCell.self)
    }
    
    internal static func makeAcknowladgementsSection() -> Section<UIView> {
        let message = """
        Upon confirming your purchase, your iTunes account will be charged the amount displayed, which includes ProtonMail Plus, and Apple's in-app purchase fee (Apple charges a fee of approximately 30% on purchases made through your iPhone/iPad).
        After making the purchse, you will automatically be upgraded to ProtonMail Plus for one year period, after which time you can renew or cancel, either online or through our iOS app.
        """
        return Section(elements: [TableSectionHeader(title: message)], cellType: FirstSubviewSizedCell.self)
    }
}

infix operator ~
fileprivate func ~(_ right: ServicePlan, _ left: (Array<ServicePlan>, UIView)) -> UIView? {
    return left.0.contains(right) ? left.1 : nil
}
