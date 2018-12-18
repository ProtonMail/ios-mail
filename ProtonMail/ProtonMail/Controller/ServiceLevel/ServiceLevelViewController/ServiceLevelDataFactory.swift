//
//  ServiceLevelDataFactory.swift
//  ProtonMail - Created on 23/08/2018.
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


import Foundation

enum ServiceLevelDataFactory {
    internal static func makeLogoSection(plan: ServicePlan) -> Section<UIView> {
        let image = UIImage(named: "Logo")?.withRenderingMode(.alwaysTemplate)
        let headerView = ServicePlanHeader(image: image, title: plan.headerText, subicon: plan.subheader)
        return Section(elements: [headerView], cellType: AutoLayoutSizedCell.self)
    }
    
    typealias SPC = ServicePlanCapability
    internal static func makeCapabilitiesSection(plan: ServicePlan, details: ServicePlanDetails) -> Section<UIView> {
        var body = [NSAttributedString.Key: Any]()
        body[.font] = UIFont.preferredFont(forTextStyle: .body)
        
        let multiuser1 = plan ~ ([.pro], SPC(image: UIImage(named:"iap_users"),
                                             title: .init(string: LocalString._unlimited_messages_sent, attributes: body)))
        
        let multiuser2 = plan ~ ([.visionary], SPC(image: UIImage(named:"iap_users"),
                                                   title: .init(string: String(format: LocalString._up_to_n_users, details.maxMembers), attributes: body)))
        
        
        var emailAddressesString = String(format: details.maxAddresses > 1 ? LocalString._n_email_addresses : LocalString._n_email_address, details.maxAddresses)
        switch plan {
        case .pro: emailAddressesString += LocalString._per_user
        case .visionary: emailAddressesString += " " + LocalString._total
        default: break
        }
        let emailAddresses = SPC(image: UIImage(named: "iap_email"),
                                 title: .init(string: emailAddressesString, attributes: body))
        
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        let storageString = String(format: LocalString._storage_capacity, formatter.string(fromByteCount: Int64(details.maxSpace)))
        let storage = SPC(image: UIImage(named: "iap_hdd"), title: .init(string: storageString, attributes: body))
        
        let messageLimit = plan ~ ([.free], SPC(image: UIImage(named: "iap_lock"),
                                                title: .init(string: LocalString._limited_to_150_messages, attributes: body)))
        
        let bridge = plan ~ ([.plus, .pro, .visionary], SPC(image: UIImage(named: "iap_link"),
                                                            title: .init(string: LocalString._bridge_support, attributes: body)))
        
        let labels = plan ~ ([.plus, .pro, .visionary], SPC(image: UIImage(named: "iap_folder"),
                                                            title: .init(string: LocalString._labels_folders_filters, attributes: body)))
        
        let support = plan ~ ([.pro, .visionary], SPC(image: UIImage(named: "iap_lifering"),
                                                      title: .init(string: String(format: LocalString._support_n_domains, details.maxDomains), attributes: body)))
        
        let vpn = plan ~ ([.visionary], SPC(image: UIImage(named: "iap_vpn"),
                                            title: .init(string: LocalString._vpn_included, attributes: body)))
        
        let capabilities = [multiuser1, multiuser2, emailAddresses, storage, messageLimit, bridge, labels, support, vpn].compactMap { $0 }
        return Section(elements: capabilities, cellType: FirstSubviewSizedCell.self)
    }
    
    internal static func makeUnavailablePlanStatusSection(plan: ServicePlan) -> Section<UIView> {
        var regularAttributes = [NSAttributedString.Key: Any]()
        regularAttributes[.font] = UIFont.preferredFont(forTextStyle: .body)
        var coloredAttributes = regularAttributes
        coloredAttributes[.foregroundColor] = plan.subheader.1
        
        let title1 = NSMutableAttributedString(string: LocalString._migrate_beginning, attributes: regularAttributes)
        let title2 = NSMutableAttributedString(string: plan.subheader.0, attributes: coloredAttributes)
        let title3 = NSMutableAttributedString(string: LocalString._migrate_end, attributes: regularAttributes)
        
        title1.append(title2)
        title1.append(title3)
        let footerView = ServicePlanFooter(title: title1)
        
        return Section(elements: [footerView], cellType: AutoLayoutSizedCell.self)
    }
    
    internal static func makeCurrentPlanStatusSection(subscription: Subscription) -> Section<UIView> {
        var message: NSAttributedString!
        var regularAttributes = [NSAttributedString.Key: Any]()
        regularAttributes[.font] = UIFont.preferredFont(forTextStyle: .body)
        var coloredAttributes = regularAttributes
        coloredAttributes[.foregroundColor] = subscription.plan.subheader.1
        
        switch subscription.plan {
        case .free:
            message = NSAttributedString(string: LocalString._upgrade_to_paid, attributes: regularAttributes)
        case .plus, .pro, .visionary:
            let formatter = DateFormatter()
            formatter.timeStyle = .none
            formatter.dateStyle = .short
            
            if let end = subscription.end {
                let title0 = subscription.hadOnlinePayments ? LocalString._will_renew : LocalString._active_until
                let title1 = NSMutableAttributedString(string: title0 + " ", attributes: regularAttributes)
                let title2 = NSAttributedString(string: formatter.string(from: end), attributes: coloredAttributes)
                title1.append(title2)
                message = title1
            }
        }
        let footerView = ServicePlanFooter(title: message)
        
        return Section(elements: [footerView], cellType: AutoLayoutSizedCell.self)
    }
    
    internal static func makeLinksSection(except currentPlan: ServicePlan? = nil) -> Section<UIView> {
        let links: [UIView] = [ServicePlan.free, ServicePlan.plus /*, ServicePlan.pro, ServicePlan.visionary*/].compactMap { plan in
            guard plan != currentPlan else {
                return nil
            }
            let titleColored = NSAttributedString(string: plan.subheader.0.uppercased(),
                                                  attributes: [.foregroundColor : UIColor.ProtonMail.ButtonBackground,
                                                               .font: UIFont.preferredFont(forTextStyle: .body)])
            var body = [NSAttributedString.Key: Any]()
            body[.font] = UIFont.preferredFont(forTextStyle: .body)
            let attributed = NSMutableAttributedString(string: "ProtonMail ", attributes: body)
            attributed.append(titleColored)
            return ServicePlanCapability(title: attributed, serviceIconVisible: true, context: ServiceLevelCoordinator.Destination.details(of: plan))
        }
        
        return Section(elements: links, cellType: FirstSubviewSizedCell.self)
    }
    
    internal static func makeSectionHeader(_ text: String) -> Section<UIView> {
        return Section(elements: [TableSectionHeader(title: text, textAlignment: .left)], cellType: FirstSubviewSizedCell.self)
    }
    
    internal static func makeBuyLinkSection() -> Section<UIView>? {
        var body = [NSAttributedString.Key: Any]()
        body[.font] = UIFont.preferredFont(forTextStyle: .body)
        let blank = TableSectionHeader(title: " ", textAlignment: .center)
        let buyMore = ServicePlanCapability(title: NSAttributedString(string: LocalString._buy_more_credits, attributes: body),
                                            serviceIconVisible: true,
                                            context: ServiceLevelCoordinator.Destination.buyMore)
        return Section(elements: [blank, buyMore], cellType: FirstSubviewSizedCell.self)
    }
    
    internal static func makeBuyButtonSection(plan: ServicePlan, delegate: ServiceLevelDataSourceDelegate) -> Section<UIView>? {
        guard let productId = plan.storeKitProductId,
            let price = StoreKitManager.default.priceLabelForProduct(id: productId) else
        {
            let noStoreFooter = ServicePlanFooter(subTitle: LocalString._cant_connect_to_store)
            return Section(elements: [noStoreFooter], cellType: AutoLayoutSizedCell.self)
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = price.1
        formatter.maximumFractionDigits = 2
        
        let tier54 = ServicePlanDataService.shared.proceedTier54
        let total = price.0 as Decimal
        let appleFee = tier54.isZero ? total * 0.75 : total - tier54
        let pmPrice = tier54.isZero ? total * 0.25 : tier54
        
        guard let priceString = formatter.string(from: total as NSNumber),
            let originalPriceString = formatter.string(from: pmPrice as NSNumber),
            let feeString = formatter.string(from: appleFee as NSNumber) else
        {
            return nil
        }
        let title = NSMutableAttributedString(string: priceString,
                                              attributes: [.font: UIFont.preferredFont(forTextStyle: .title1),
                                                           .foregroundColor: UIColor.white])
        let caption = NSAttributedString(string: "\n" + LocalString._for_one_year,
                                         attributes: [.font: UIFont.preferredFont(forTextStyle: .body),
                                                      .foregroundColor: UIColor.white])
        title.append(caption)
        let subtitle = "" // String(format: "%@ ProtonMail %@\n%@ %@", originalPriceString, plan.subheader.0, feeString, LocalString._iap_fee)
        let buttonAction: (UIButton?)->Void = { _ in
            delegate.purchaseProduct(id: productId)
        }
        let footerView = ServicePlanFooter(subTitle: subtitle,
                                           buttonTitle: title,
                                           buttonEnabled: delegate.canPurchaseProduct(id: productId),
                                           buttonAction: buttonAction)
        return Section(elements: [footerView], cellType: AutoLayoutSizedCell.self)
    }
    
    internal static func makeAcknowladgementsSection() -> Section<UIView> {
        return Section(elements: [TableSectionHeader(title: LocalString._iap_disclamer, textAlignment: .center)], cellType: FirstSubviewSizedCell.self)
    }
}

infix operator ~
fileprivate func ~(_ right: ServicePlan, _ left: (Array<ServicePlan>, UIView)) -> UIView? {
    return left.0.contains(right) ? left.1 : nil
}
