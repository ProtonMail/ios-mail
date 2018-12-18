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

    internal enum Sections: Int {
        case logo = 0, detail, annotation, subsectionHeader, others
        static let count = 5
        
        var indexSet: IndexSet {
            return IndexSet(integer: self.rawValue)
        }
    }
    
    @objc dynamic var title: String = ""
    @objc dynamic var logoItem: AnyStorefrontItem = AnyStorefrontItem()
    @objc dynamic var detailItems: [AnyStorefrontItem] = []
    @objc dynamic var annotationItem: AnyStorefrontItem = AnyStorefrontItem()
    @objc dynamic var subsectionHeaderItem: AnyStorefrontItem?
    @objc dynamic var othersItems: [AnyStorefrontItem] = []

    init(storefront: Storefront) {
        self.storefront = storefront
        
        super.init()
        
        defer {
            self.storefrontObserver = self.observe(\.storefront, options: [.initial, .new]) { [unowned self] viewModel, change in
                self.title = storefront.title
                
                self.logoItem = self.extractLogo(from: viewModel.storefront)
                self.detailItems = self.extractDetails(from: viewModel.storefront)
                self.annotationItem = self.extractAnnotation(from: viewModel.storefront)
                self.othersItems = self.extractOthers(from: viewModel.storefront)
                self.subsectionHeaderItem = self.othersItems.isEmpty ? nil : SubsectionHeaderStorefrontItem(text: LocalString._other_plans)
            }
        }
    }
    
    func numberOfSections() -> Int {
        return Sections.count
    }
    
    func numberOfItems(in section: Int) -> Int {
        guard let section = Sections(rawValue: section) else {
            fatalError()
        }
        switch section {
        case .logo:              return 1
        case .detail:            return self.detailItems.count
        case .annotation:        return 1
        case .subsectionHeader:  return self.subsectionHeaderItem == nil ? 0 : 1
        case .others:            return self.othersItems.count
        }
    }
    
    func item(for indexPath: IndexPath) -> AnyStorefrontItem {
        guard let section = Sections(rawValue: indexPath.section) else {
            fatalError()
        }
        switch section {
        case .logo:                                                      return self.logoItem
        case .detail:                                                    return self.detailItems[indexPath.row]
        case .annotation:                                                return self.annotationItem
        case .subsectionHeader where self.subsectionHeaderItem != nil:   return self.subsectionHeaderItem!
        case .others:                                                    return self.othersItems[indexPath.row]
        default:                                                         fatalError()
        }
    }
    
    func plan(at indexPath: IndexPath) -> ServicePlan? {
        guard let section = Sections(rawValue: indexPath.section) else {
            fatalError()
        }
        switch section {
        case .others:   return self.storefront.others[indexPath.row]
        default:        return nil
        }
    }
}

extension StorefrontViewModel {
    private func extractLogo(from storefront: Storefront) -> AnyStorefrontItem {
        return LogoStorefrontItem(imageName: "Logo",
                                  title: storefront.plan.headerText,
                                  subtitle: storefront.plan.subheader)
    }
    
    private func extractDetails(from storefront: Storefront) -> [AnyStorefrontItem] {
        let details = storefront.details
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
    
    private func extractAnnotation(from storefront: Storefront) -> AnyStorefrontItem {
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
        case .some(let subscription):
            return AnnotationStorefrontItem(text: makeCurrentPlanText(subscription: subscription))
        case .none:
            return AnnotationStorefrontItem(text: makeUnavailablePlanText(plan: storefront.plan))
        }
    }
    
    private func extractOthers(from storefront: Storefront) -> [AnyStorefrontItem] {
        return storefront.others.map { plan in
            let titleColored = NSAttributedString(string: plan.subheader.0.uppercased(), attributes: [.foregroundColor : UIColor.ProtonMail.ButtonBackground,
                                                                                                      .font: UIFont.preferredFont(forTextStyle: .body)])
            var body = [NSAttributedString.Key: Any]()
            body[.font] = UIFont.preferredFont(forTextStyle: .body)
            let attributed = NSMutableAttributedString(string: "ProtonMail ", attributes: body)
            attributed.append(titleColored)
            return LinkStorefrontItem(text: attributed)
        }
    }
}
