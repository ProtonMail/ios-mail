//
//  StorefrontViewModel.swift
//  ProtonMail - Created on 16/12/2018.
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

class StorefrontViewModel: NSObject {
    @objc dynamic private var storefront: Storefront
    private var storefrontObserver: NSKeyValueObservation!
    private var canPurchaseObserver: NSKeyValueObservation!
    private var storefrontSubscriptionObserver: NSKeyValueObservation!
    
    internal enum Sections: Int {
        case logo = 0, detail, annotation, buyLinkHeader, buyLink, othersHeader, others, buyButton, disclaimer
        static let count = 9 // TODO: update this on swift4.3  with allCases.count
        
        var indexSet: IndexSet {
            return .init(integer: self.rawValue)
        }
    }
    
    internal var currentSubscription: Subscription?
    @objc dynamic var title: String = ""
    @objc dynamic var logoItem: AnyStorefrontItem?
    @objc dynamic var detailItems: [AnyStorefrontItem] = []
    @objc dynamic var annotationItem: AnyStorefrontItem?
    @objc dynamic var buyLinkHeaderItem: AnyStorefrontItem?
    @objc dynamic var othersHeaderItem: AnyStorefrontItem?
    @objc dynamic var othersItems: [AnyStorefrontItem] = []
    @objc dynamic var buyLinkItem: AnyStorefrontItem?
    @objc dynamic var buyButtonItem: AnyStorefrontItem?
    @objc dynamic var disclaimerItem: AnyStorefrontItem?
    
    init(storefront: Storefront) {
        self.storefront = storefront
        
        func setup(with storefront: Storefront) {
            self.title = storefront.title
            self.currentSubscription = storefront.subscription
            
            self.logoItem = self.extractLogo(from: storefront)
            self.detailItems = self.extractDetails(from: storefront)
            self.annotationItem = self.extractAnnotation(from: storefront)
            self.othersItems = self.extractOthers(from: storefront)
            self.othersHeaderItem = self.othersItems.isEmpty ? nil : SubsectionHeaderStorefrontItem(text: LocalString._other_plans)
            self.buyLinkItem = self.extractBuyLink(from: storefront)
            self.buyLinkHeaderItem = self.buyLinkItem == nil ? nil : SubsectionHeaderStorefrontItem(text: " ")
            self.buyButtonItem = self.extractBuyButton(from: storefront)
            self.disclaimerItem = self.extractDisclaimer(from: storefront)
        }
        
        super.init()
        setup(with: storefront)
        
        self.storefrontObserver = self.observe(\.storefront, options: [.new]) { viewModel, change in
            setup(with: viewModel.storefront)
        }
        self.canPurchaseObserver = self.storefront.observe(\.isProductPurchasable, options: [.new]) { [unowned self] storefront, change in
            self.buyButtonItem = self.extractBuyButton(from: storefront)
        }
        self.storefrontSubscriptionObserver = self.storefront.observe(\.subscription, options: [.new]) { [unowned self] storefront, change in
            self.storefront = storefront
        }
    }
    
    func numberOfSections() -> Int {
        return Sections.count
    }
    
    func numberOfItems(in section: Int) -> Int {
        guard let section = Sections(rawValue: section) else {
            assert(false, "Incorrect number of section")
            return 0
        }
        switch section {
        case .detail:            return self.detailItems.count
        case .others:            return self.othersItems.count
        case .logo:              return NSNumber(value: self.logoItem != nil).intValue
        case .annotation:        return NSNumber(value: self.annotationItem != nil).intValue
        case .othersHeader:      return NSNumber(value: self.othersHeaderItem != nil).intValue
        case .buyLinkHeader:     return NSNumber(value: self.buyLinkHeaderItem != nil).intValue
        case .buyLink:           return NSNumber(value: self.buyLinkItem != nil).intValue
        case .buyButton:         return NSNumber(value: self.buyButtonItem != nil).intValue
        case .disclaimer:        return NSNumber(value: self.disclaimerItem != nil).intValue
        }
    }
    
    func item(for indexPath: IndexPath) -> AnyStorefrontItem {
        guard let section = Sections(rawValue: indexPath.section) else {
            assert(false, "Incorrect number of section")
            return AnyStorefrontItem()
        }
        switch section {
        case .detail:                                               return self.detailItems[indexPath.row]
        case .others:                                               return self.othersItems[indexPath.row]
        case .logo where self.logoItem != nil:                      return self.logoItem!
        case .annotation where self.annotationItem != nil:          return self.annotationItem!
        case .othersHeader where self.othersHeaderItem != nil:      return self.othersHeaderItem!
        case .buyLinkHeader where self.buyLinkHeaderItem != nil:    return self.buyLinkHeaderItem!
        case .buyLink where self.buyLinkItem != nil:                return self.buyLinkItem!
        case .buyButton where self.buyButtonItem != nil:            return self.buyButtonItem!
        case .disclaimer where self.disclaimerItem != nil:          return self.disclaimerItem!
        default:
            assert(false, "Attempt to get incorrect section")
            return AnyStorefrontItem()
        }
    }
    
    func plan(at indexPath: IndexPath) -> ServicePlan? {
        guard let section = Sections(rawValue: indexPath.section) else {
            assert(false, "Attempt to get incorrect section")
            return nil
        }
        switch section {
        case .others: return self.storefront.others[indexPath.row]
        default: break
        }
        return nil
    }
}

extension StorefrontViewModel {
    func buy() {
        self.storefront.buyProduct()
    }
}

// almost exactly copied from previous version of IAP UI
extension StorefrontViewModel {
    private func extractLogo(from storefront: Storefront) -> AnyStorefrontItem? {
        guard let _ = storefront.details else { return nil }
        return LogoStorefrontItem(imageName: "Logo",
                                  title: storefront.plan.headerText,
                                  subtitle: storefront.plan.subheader)
    }
    
    private func extractDetails(from storefront: Storefront) -> [AnyStorefrontItem] {
        guard let details = storefront.details else {
            return []
        }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        
        switch storefront.plan {
        case .free:
            return [
                DetailStorefrontItem(imageName: "iap_email", text: String(format: details.maxAddresses > 1 ? LocalString._n_email_addresses : LocalString._n_email_address, details.maxAddresses)),
                DetailStorefrontItem(imageName: "iap_hdd", text: String(format: LocalString._storage_capacity, formatter.string(fromByteCount: Int64(details.maxSpace)))),
                DetailStorefrontItem(imageName: "iap_lock", text: LocalString._limited_to_150_messages)
            ]
        case .plus:
            return [
                DetailStorefrontItem(imageName: "iap_email", text: String(format: details.maxAddresses > 1 ? LocalString._n_email_addresses : LocalString._n_email_address, details.maxAddresses)),
                DetailStorefrontItem(imageName: "iap_hdd", text: String(format: LocalString._storage_capacity, formatter.string(fromByteCount: Int64(details.maxSpace)))),
                DetailStorefrontItem(imageName: "iap_link", text: LocalString._bridge_support),
                DetailStorefrontItem(imageName: "iap_folder", text: LocalString._labels_folders_filters)
            ]
        case .pro:
            return [
                DetailStorefrontItem(imageName: "iap_users", text: LocalString._unlimited_messages_sent),
                DetailStorefrontItem(imageName: "iap_email", text: String(format: details.maxAddresses > 1 ? LocalString._n_email_addresses : LocalString._n_email_address, details.maxAddresses) + LocalString._per_user),
                DetailStorefrontItem(imageName: "iap_hdd", text: String(format: LocalString._storage_capacity, formatter.string(fromByteCount: Int64(details.maxSpace)))),
                DetailStorefrontItem(imageName: "iap_link", text: LocalString._bridge_support),
                DetailStorefrontItem(imageName: "iap_folder", text: LocalString._labels_folders_filters),
                DetailStorefrontItem(imageName: "iap_lifering", text: String(format: LocalString._support_n_domains, details.maxDomains))
            ]
        case .visionary:
            return [
                DetailStorefrontItem(imageName: "iap_users", text: String(format: LocalString._up_to_n_users, details.maxMembers)),
                DetailStorefrontItem(imageName: "iap_email", text: String(format: details.maxAddresses > 1 ? LocalString._n_email_addresses : LocalString._n_email_address, details.maxAddresses) + LocalString._total),
                DetailStorefrontItem(imageName: "iap_hdd", text: String(format: LocalString._storage_capacity, formatter.string(fromByteCount: Int64(details.maxSpace)))),
                DetailStorefrontItem(imageName: "iap_link", text: LocalString._bridge_support),
                DetailStorefrontItem(imageName: "iap_folder", text: LocalString._labels_folders_filters),
                DetailStorefrontItem(imageName: "iap_lifering", text: String(format: LocalString._support_n_domains, details.maxDomains)),
                DetailStorefrontItem(imageName: "iap_vpn", text: LocalString._vpn_included)
            ]
        }
    }
    
    private func extractAnnotation(from storefront: Storefront) -> AnyStorefrontItem? {
        func makeUnavailablePlanText(plan: ServicePlan) -> NSAttributedString {
            var regularAttributes = [NSAttributedString.Key: Any]()
            regularAttributes[.font] = UIFont.preferredFont(forTextStyle: .body)
            var coloredAttributes = regularAttributes
            coloredAttributes[.foregroundColor] = plan.subheader.1
            
            let title1 = NSMutableAttributedString(string: LocalString._migrate_beginning, attributes: regularAttributes)
            let title2 = NSMutableAttributedString(string: plan.subheader.0, attributes: coloredAttributes)
            let title3 = NSMutableAttributedString(string: LocalString._migrate_end, attributes: regularAttributes)
            
            title1.append(title2)
            title1.append(title3)
            return title1
        }
        func makeCurrentPlanText(subscription: Subscription) -> NSAttributedString {
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
            return message ?? NSAttributedString()
        }
        
        switch storefront.subscription {
        case .some(let subscription):
            return AnnotationStorefrontItem(text: makeCurrentPlanText(subscription: subscription))
        case .none where !storefront.isProductPurchasable:
            return AnnotationStorefrontItem(text: makeUnavailablePlanText(plan: storefront.plan))
        case .none where storefront.isProductPurchasable:
            return nil
            
        default: return nil
        }
    }
    
    private func extractOthers(from storefront: Storefront) -> [AnyStorefrontItem] {
        return storefront.others.map { plan in
            let titleColored = NSAttributedString(string: plan.subheader.0.uppercased(),
                                                  attributes: [.foregroundColor : UIColor.ProtonMail.ButtonBackground,
                                                               .font: UIFont.preferredFont(forTextStyle: .body)])
            var body = [NSAttributedString.Key: Any]()
            body[.font] = UIFont.preferredFont(forTextStyle: .body)
            let attributed = NSMutableAttributedString(string: "ProtonMail ", attributes: body)
            attributed.append(titleColored)
            return LinkStorefrontItem(text: attributed)
        }
    }
    
    private func extractBuyButton(from storefront: Storefront) -> AnyStorefrontItem? {
        guard storefront.isProductPurchasable,
            let productId = storefront.plan.storeKitProductId,
            let price = StoreKitManager.default.priceLabelForProduct(id: productId) else
        {
            return nil
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
        
        // once it was a subtitle, but apple review team did not apprive it
        let _ = String(format: "%@ ProtonMail %@\n%@ %@", originalPriceString, storefront.plan.subheader.0, feeString, LocalString._iap_fee)
        
        let title = NSMutableAttributedString(string: priceString,
                                              attributes: [.font: UIFont.preferredFont(forTextStyle: .title1),
                                                           .foregroundColor: UIColor.white])
        let caption = NSAttributedString(string: "\n" + LocalString._for_one_year,
                                         attributes: [.font: UIFont.preferredFont(forTextStyle: .body),
                                                      .foregroundColor: UIColor.white])
        title.append(caption)
        
        return BuyButtonStorefrontItem(subtitle: nil, buttonTitle: title, buttonEnabled: true)
    }
    
    private func extractDisclaimer(from storefront: Storefront) -> AnyStorefrontItem? {
        guard storefront.isProductPurchasable else {
            return nil
        }
        return DisclaimerStorefrontItem(text: LocalString._iap_disclamer)
    }
    
    private func extractBuyLink(from storefront: Storefront) -> AnyStorefrontItem? {
        guard storefront.canBuyMoreCredits else {
            return nil
        }
        
        var body = [NSAttributedString.Key: Any]()
        body[.font] = UIFont.preferredFont(forTextStyle: .body)
        return LinkStorefrontItem(text: NSAttributedString(string:LocalString._buy_more_credits, attributes: body))
    }
}
