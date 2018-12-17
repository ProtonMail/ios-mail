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
    @objc dynamic var title: String
    @objc dynamic var storefront: Storefront
    private var storefrontObserver: NSKeyValueObservation!
    
    private var detailItems: [StorefrontItem] = []
    private var othersItems: [StorefrontItem] = []
    
    init(storefront: Storefront) {
        self.storefront = storefront
        self.title = storefront.title
        super.init()
        
        defer {
            self.storefrontObserver = self.observe(\.storefront, options: [.initial, .new], changeHandler: { viewModel, change in
                self.title = storefront.title
                self.detailItems = self.extractDetails(from: viewModel.storefront)
                self.othersItems = self.extractOthers(from: viewModel.storefront)
            })
        }
    }
    
    func numberOfSections() -> Int {
        return 5
    }
    
    func numberOfItems(in section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return self.detailItems.count
        case 2: return 1
        case 3: return 1
        case 4: return self.othersItems.count
        default: return 0
        }
    }
    
    func item(for indexPath: IndexPath) -> StorefrontItem {
        switch indexPath.section {
        case 0: return self.extractLogo(from: self.storefront)
        case 1: return self.detailItems[indexPath.row]
        case 2: return self.extractAnnotation(from: self.storefront)
        case 3: return .subsectionHeader(text: LocalString._other_plans)
        case 4: return self.othersItems[indexPath.row]
            
        default:
            fatalError()
        }
    }
    
    func plan(at indexPath: IndexPath) -> ServicePlan? {
        switch indexPath.section {
        case 4: return self.storefront.others[indexPath.row]
        default: return nil
        }
    }

}

extension StorefrontViewModel {
    private func extractLogo(from storefront: Storefront) -> StorefrontItem {
        return StorefrontItem.logo(imageName: "Logo",
                                   title: storefront.plan.headerText,
                                   subtitle: storefront.plan.subheader)
    }
    
    private func extractDetails(from storefront: Storefront) -> [StorefrontItem] {
        let details = storefront.details
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        
        switch storefront.plan {
        case .free:
            return [
                .detail(imageName: "iap_email",
                        description: String(format: details.maxAddresses > 1 ? LocalString._n_email_addresses : LocalString._n_email_address, details.maxAddresses)),
                .detail(imageName: "iap_hdd",
                        description: String(format: LocalString._storage_capacity, formatter.string(fromByteCount: Int64(details.maxSpace)))),
                .detail(imageName: "iap_lock",
                        description: LocalString._limited_to_150_messages)
            ]
        case .plus:
            return [
                .detail(imageName: "iap_email",
                        description: String(format: details.maxAddresses > 1 ? LocalString._n_email_addresses : LocalString._n_email_address, details.maxAddresses)),
                .detail(imageName: "iap_hdd",
                        description: String(format: LocalString._storage_capacity, formatter.string(fromByteCount: Int64(details.maxSpace)))),
                .detail(imageName: "iap_link",
                        description: LocalString._bridge_support),
                .detail(imageName: "iap_folder",
                        description: LocalString._labels_folders_filters)
            ]
        case .pro:
            return [
                .detail(imageName: "iap_users",
                        description: LocalString._unlimited_messages_sent),
                .detail(imageName: "iap_email",
                        description: String(format: details.maxAddresses > 1 ? LocalString._n_email_addresses : LocalString._n_email_address, details.maxAddresses) + LocalString._per_user),
                .detail(imageName: "iap_hdd",
                        description: String(format: LocalString._storage_capacity, formatter.string(fromByteCount: Int64(details.maxSpace)))),
                .detail(imageName: "iap_link",
                        description: LocalString._bridge_support),
                .detail(imageName: "iap_folder",
                        description: LocalString._labels_folders_filters),
                .detail(imageName: "iap_lifering",
                        description: String(format: LocalString._support_n_domains, details.maxDomains))
            ]
        case .visionary:
            return [
                .detail(imageName: "iap_users",
                        description: String(format: LocalString._up_to_n_users, details.maxMembers)),
                .detail(imageName: "iap_email",
                        description: String(format: details.maxAddresses > 1 ? LocalString._n_email_addresses : LocalString._n_email_address, details.maxAddresses) + LocalString._total),
                .detail(imageName: "iap_hdd",
                        description: String(format: LocalString._storage_capacity, formatter.string(fromByteCount: Int64(details.maxSpace)))),
                .detail(imageName: "iap_link",
                        description: LocalString._bridge_support),
                .detail(imageName: "iap_folder",
                        description: LocalString._labels_folders_filters),
                .detail(imageName: "iap_lifering",
                        description: String(format: LocalString._support_n_domains, details.maxDomains)),
                .detail(imageName: "iap_vpn",
                        description: LocalString._vpn_included)
            ]
        }
    }
    
    private func extractAnnotation(from storefront: Storefront) -> StorefrontItem {
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
            return message
        }
        
        switch storefront.subscription {
        case .some(let subscription): return .annotation(text: makeCurrentPlanText(subscription: subscription))
        case .none: return .annotation(text: makeUnavailablePlanText(plan: storefront.plan))
        }
    }
    
    private func extractOthers(from storefront: Storefront) -> [StorefrontItem] {
        return storefront.others.map { plan in
            let titleColored = NSAttributedString(string: plan.subheader.0.uppercased(),
                                                                  attributes: [.foregroundColor : UIColor.ProtonMail.ButtonBackground,
                                                                               .font: UIFont.preferredFont(forTextStyle: .body)])
            var body = [NSAttributedString.Key: Any]()
            body[.font] = UIFont.preferredFont(forTextStyle: .body)
            let attributed = NSMutableAttributedString(string: "ProtonMail ", attributes: body)
            attributed.append(titleColored)
            return .link(text: attributed)
        }
    }
}

class Storefront: NSObject {
    var subscription: Subscription?
    var plan: ServicePlan
    var details: ServicePlanDetails
    var others: [ServicePlan]
    var title: String
    
    init(plan: ServicePlan) {
        self.plan = plan
        self.details = plan.fetchDetails()!
        self.others = []
        self.title = plan.subheader.0
    }
    
    init(subscription: Subscription) {
        self.subscription = subscription
        self.plan = subscription.plan
        self.details = subscription.details
        self.others = Array<ServicePlan>.init(arrayLiteral: .free, .plus, .pro, .visionary).filter({ $0 != subscription.plan })
        self.title = LocalString._menu_service_plan_title
    }
}

enum StorefrontItem {
    case logo(imageName: String, title: String, subtitle: (String, UIColor)) // FIXME: NSAttributedString instead of color
    case detail(imageName: String, description: String)
    case annotation(text: NSAttributedString)
    case subsectionHeader(text: String)
    case link(text: NSAttributedString)
//    case buyButton(title: String)
//    case disclaimer(text: String)
}
