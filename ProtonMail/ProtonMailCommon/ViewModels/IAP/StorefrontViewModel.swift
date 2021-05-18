//
//  StorefrontViewModel.swift
//  ProtonMail - Created on 16/12/2018.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.
    

import Foundation
import PromiseKit
import PMAuthentication
import PMCommon
import PMPayments

class StorefrontViewModel: NSObject {
    let currentUser: UserManager
    @objc dynamic private var storefront: Storefront!
    private var storefrontObserver: NSKeyValueObservation!
    private var canPurchaseObserver: NSKeyValueObservation!
    private var storefrontSubscriptionObserver: NSKeyValueObservation!
    private var storefrontCreditsObserver: NSKeyValueObservation!
    
    private var servicePlanService: ServicePlanDataService!
    
    internal enum Sections: Int, CaseIterable {
        case logo = 0, detail, annotation, buyLinkHeader, buyLink, othersHeader, others, buyButton, credits, disclaimer
        
        var indexSet: IndexSet {
            return .init(integer: self.rawValue)
        }
    }
    
    internal var currentSubscription: ServicePlanSubscription?
    @objc dynamic var title: String = ""
    @objc dynamic var logoItem: AnyStorefrontItem?
    @objc dynamic var detailItems: [AnyStorefrontItem] = []
    @objc dynamic var annotationItem: AnyStorefrontItem?
    @objc dynamic var buyLinkHeaderItem: AnyStorefrontItem?
    @objc dynamic var othersHeaderItem: AnyStorefrontItem?
    @objc dynamic var othersItems: [AnyStorefrontItem] = []
    @objc dynamic var buyLinkItem: AnyStorefrontItem?
    @objc dynamic var buyButtonItem: AnyStorefrontItem?
    @objc dynamic var creditsItem: AnyStorefrontItem?
    @objc dynamic var disclaimerItem: AnyStorefrontItem?

    var isHavingVpnPlanInCurrentSubscription: Bool = false
    
    init(currentUser: UserManager, storefront: Storefront? = nil, havingVpnPlan: Bool = false) {
        self.currentUser = currentUser
        self.storefront = storefront
        self.isHavingVpnPlanInCurrentSubscription = havingVpnPlan
        super.init()
    }
    
    func updateSubscription() -> Promise<Void> {
        guard self.storefront == nil else {
            // Check next plan data
            self.initStoreFront()
            self.servicePlanService = self.currentUser.sevicePlanService
            self.setup(with: self.storefront)
            self.setupObserve()
            return Promise()
        }

        return Promise { (seal) in
            let authenticator = Authenticator(api: self.currentUser.apiService)
            let auth = self.currentUser.auth
            authenticator.getUserInfo(Credential(auth)) { (result) in
                switch result {
                case .success(let userInfo):
                    self.isHavingVpnPlanInCurrentSubscription = userInfo.subscribed == 4
                case .failure(_):
                    break
                }
                seal.fulfill_()
            }
        }.then { () -> Promise<Void> in
            return self.currentUser.sevicePlanService.updateServicePlans()
        }.then { () -> Promise<Void> in
            guard self.currentUser.sevicePlanService.isIAPAvailable else {
                throw NSError(domain: "", code: -1, localizedDescription: "IAP unavailable")
            }
            return self.currentUser.sevicePlanService.updateCurrentSubscription()
        }.done {
            self.initStoreFront()
            self.servicePlanService = self.currentUser.sevicePlanService
            self.setup(with: self.storefront)
            self.setupObserve()
        }
    }
    
    func numberOfSections() -> Int {
        return Sections.allCases.count
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
        case .credits:           return NSNumber(value: self.creditsItem != nil).intValue
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
        case .credits where self.creditsItem != nil:                return self.creditsItem!
        case .disclaimer where self.disclaimerItem != nil:          return self.disclaimerItem!
        default:
            assert(false, "Attempt to get incorrect section")
            return AnyStorefrontItem()
        }
    }
    
    func plan(at indexPath: IndexPath) -> AccountPlan? {
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
    func buy(successHandler: @escaping ()->Void,
             errorHandler: @escaping (Error)->Void)
    {
        self.storefront.buyProduct(successHandler: successHandler, errorHandler: errorHandler)
    }
}

// almost exactly copied from previous version of IAP UI
extension StorefrontViewModel {
    private func setup(with storefront: Storefront) {
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
        self.creditsItem = self.buyButtonItem == nil ? nil : self.extractCredits(from: storefront)
        self.disclaimerItem = self.extractDisclaimer(from: storefront)
    }
    
    private func setupObserve() {
        self.storefrontObserver = self.observe(\.storefront, options: [.new]) { viewModel, change in
            self.setup(with: viewModel.storefront)
        }
        self.canPurchaseObserver = self.storefront.observe(\.isProductPurchasable, options: [.new]) { [unowned self] storefront, change in
            self.buyButtonItem = self.extractBuyButton(from: storefront)
        }
        self.storefrontSubscriptionObserver = self.storefront.observe(\.subscription, options: [.new]) { [unowned self] storefront, change in
            self.storefront = storefront
        }
        self.storefrontCreditsObserver = self.storefront.observe(\.credits, options: [.new]) { [unowned self] storefront, change in
            self.annotationItem = self.extractAnnotation(from: storefront)
            self.creditsItem = self.buyButtonItem == nil ? nil : self.extractCredits(from: storefront)
        }
    }
    
    private func initStoreFront() {
        guard self.storefront == nil else {return}
        
        if let currentSubscription = self.currentUser.sevicePlanService.currentSubscription {
            self.storefront = Storefront(subscription: currentSubscription, servicePlanService: self.currentUser.sevicePlanService, user: self.currentUser.userInfo)
        } else {
            self.storefront = Storefront(plan: .free, servicePlanService: self.currentUser.sevicePlanService, user: self.currentUser.userInfo)
        }
    }
    
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
        case .mailPlus:
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
                DetailStorefrontItem(imageName: "iap_email", text: String(format: details.maxAddresses > 1 ? LocalString._n_email_addresses : LocalString._n_email_address, details.maxAddresses) + " " + LocalString._total),
                DetailStorefrontItem(imageName: "iap_hdd", text: String(format: LocalString._storage_capacity, formatter.string(fromByteCount: Int64(details.maxSpace)))),
                DetailStorefrontItem(imageName: "iap_link", text: LocalString._bridge_support),
                DetailStorefrontItem(imageName: "iap_folder", text: LocalString._labels_folders_filters),
                DetailStorefrontItem(imageName: "iap_lifering", text: String(format: LocalString._support_n_domains, details.maxDomains)),
                DetailStorefrontItem(imageName: "iap_vpn", text: LocalString._vpn_included)
            ]
        default:
            return [
                DetailStorefrontItem(imageName: "iap_email", text: String(format: details.maxAddresses > 1 ? LocalString._n_email_addresses : LocalString._n_email_address, details.maxAddresses)),
                DetailStorefrontItem(imageName: "iap_hdd", text: String(format: LocalString._storage_capacity, formatter.string(fromByteCount: Int64(details.maxSpace)))),
                DetailStorefrontItem(imageName: "iap_lock", text: LocalString._limited_to_150_messages)
            ]
        }
    }
    
    private func extractAnnotation(from storefront: Storefront) -> AnyStorefrontItem? {
        func makeUnavailablePlanText(plan: AccountPlan) -> NSAttributedString {
            var regularAttributes = [NSAttributedString.Key: Any]()
            regularAttributes[.font] = UIFont.preferredFont(forTextStyle: .body)
            var coloredAttributes = regularAttributes
            coloredAttributes[.foregroundColor] = plan.subheader.1
            let planName = plan.subheader.0
            let fullstr = String(format: LocalString._migrate_plan, planName)
            let title = NSMutableAttributedString(string: fullstr, attributes: regularAttributes)
            // if can't find the range just to use plain style
            if let range = fullstr.range(of: planName) {
                let nsRange = NSRange(range, in: fullstr)
                title.setAttributes(coloredAttributes, range: nsRange)
            }
            return title
        }

        func makeUnavailableUpgradePlanText() -> NSAttributedString {
            var regularAttributes = [NSAttributedString.Key: Any]()
            regularAttributes[.font] = UIFont.preferredFont(forTextStyle: .body)
            let title = LocalString._message_of_unavailable_to_upgrade_account
            let urlTitle = LocalString._message_of_unavailable_to_upgrade_url
            let fullTitle = String.localizedStringWithFormat(title, urlTitle)
            let attributedString = NSMutableAttributedString(string: fullTitle,
                                                             attributes: regularAttributes)
            if let subrange = fullTitle.range(of: urlTitle) {
                let nsRange = NSRange(subrange, in: fullTitle)
                attributedString.addAttribute(.foregroundColor, value: UIColor.ProtonMail.Menu_UnreadCountBackground, range: nsRange)
            }
            return attributedString
        }
        
        func makeCurrentPlanText(subscription: ServicePlanSubscription) -> NSAttributedString {
            var message: NSAttributedString!
            var regularAttributes = [NSAttributedString.Key: Any]()
            regularAttributes[.font] = UIFont.preferredFont(forTextStyle: .body)
            var coloredAttributes = regularAttributes
            coloredAttributes[.foregroundColor] = subscription.plan.subheader.1
            
            switch subscription.plan {
            case .free:
                message = NSAttributedString(string: LocalString._upgrade_to_paid, attributes: regularAttributes)
            case .mailPlus, .pro, .visionary:
                let formatter = DateFormatter()
                formatter.timeStyle = .none
                formatter.dateStyle = .short
                
                if let end = subscription.end {
                    let title0 = (subscription.hadOnlinePayments || storefront.credits > 0) ? LocalString._will_renew : LocalString._active_until
                    let title1 = NSMutableAttributedString(string: title0 + " ", attributes: regularAttributes)
                    let title2 = NSAttributedString(string: formatter.string(from: end), attributes: coloredAttributes)
                    title1.append(title2)
                    message = title1
                }
            default: message = NSAttributedString(string: LocalString._upgrade_to_paid, attributes: regularAttributes)

            }
            return message ?? NSAttributedString()
        }
        
        switch storefront.subscription {
        case .some(let subscription):
            return AnnotationStorefrontItem(text: makeCurrentPlanText(subscription: subscription))
        case .none where !storefront.isProductPurchasable && self.isHavingVpnPlanInCurrentSubscription:
            return AnnotationStorefrontItem(text: makeUnavailableUpgradePlanText())
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
            let productId = AccountPlan.mailPlus.storeKitProductId,
            let price = StoreKitManager.default.priceLabelForProduct(identifier: productId) else
        {
            return nil
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = price.1
        formatter.maximumFractionDigits = 2
        
        let tier54 = self.servicePlanService.proceedTier54
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
    
    private func extractCredits(from storefront: Storefront) -> AnyStorefrontItem? {
        guard let _ = storefront.subscription else { return nil }
        let string = NSAttributedString(string: "Current Credits balance: \(Int(storefront.credits / 100))")
        return AnnotationStorefrontItem(text: string)
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
