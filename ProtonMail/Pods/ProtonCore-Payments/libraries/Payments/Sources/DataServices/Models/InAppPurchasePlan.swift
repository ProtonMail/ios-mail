//
//  InAppPurchasePlan.swift
//  ProtonCore-Payments - Created on 30/11/2020.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCoreFeatureFlags
import ProtonCoreUtilities

public typealias ListOfIAPIdentifiers = Set<String>
public typealias ListOfShownPlanNames = Set<String>

@available(*, deprecated, renamed: "InAppPurchasePlan")
public typealias AccountPlan = InAppPurchasePlan

public struct InAppPurchasePlan: Equatable, Hashable {

    public static let defaultCycle = "12"
    public static let defaultOffer = "default"
    public static let defaultCurrency = "usd"

    public typealias ProductId = String

    public let storeKitProductId: ProductId?
    public let protonName: String
    public let offer: String?
    public var period: String?
    public let currency: String?

    public var isFreePlan: Bool { InAppPurchasePlan.isThisAFreePlan(protonName: protonName) }

    // FIXME: check if clients use this, and remove because it's too coupled anyway
    public var isPlusPlan: Bool { InAppPurchasePlan.isThisAPlusPlan(protonName: protonName) }
    public var isUnlimitedPlan: Bool { InAppPurchasePlan.isThisAUnlimitedPlan(protonName: protonName) }

    public static let freePlan: InAppPurchasePlan = .init(protonPlanName: "free", offer: nil, listOfIAPIdentifiers: [])
    public static var freePlanName: String { freePlan.protonName }

    // FIXME: these checks are possibly too coupled to plan name, and betray too much knowledge
    public static func isThisAFreePlan(protonName: String, featureFlagsRepository: FeatureFlagsRepositoryProtocol = FeatureFlagsRepository.shared) -> Bool {
        if featureFlagsRepository.isEnabled(CoreFeatureFlagType.dynamicPlan) {
            return protonName == freePlanName || protonName.containsIgnoringCase(check: "vpnfree") || protonName.containsIgnoringCase(check: "drivefree")
        } else {
            return protonName == freePlanName || protonName == "vpnfree" || protonName == "drivefree"
        }

    }

    public static func isThisAPlusPlan(protonName: String) -> Bool {
        protonName.range(of: "plus", options: .caseInsensitive) != nil
    }

    public static func isThisAUnlimitedPlan(protonName: String) -> Bool {
        protonName.range(of: "unlimited", options: .caseInsensitive) != nil
    }

    public static func isThisATrialPlan(protonName: String) -> Bool {
        protonName == "trial"
    }

    private static let regex: NSRegularExpression = {
        guard let instance = try? NSRegularExpression(
            pattern: "^ios[^_]*_([^_]*)_?(.*)_(\\d+)_(\\w+)_(?:non_|auto_)renewing(?:_v\\d+)?$",
            //                    ⬆      ⬆     ⬆     ⬆       ⬆           ⬆
            //                   name   offer  cycle currency  auto?   version suffix (optional)
            // range no.          1.      2.     3.     4.     ⇖these are not capture groups⇗
            options: [.anchorsMatchLines]
        ) else {
            assertionFailure("The regular expression was not compiled right")
            return NSRegularExpression()
        }
        return instance
    }()

    public static func protonPlanIsPresentInIAPIdentifierList(protonPlan: Plan, identifiers: ListOfIAPIdentifiers) -> Bool {
        if let iapIdentifiers = protonPlan.vendors?.apple.plans.values {
            for iapIdentifier in iapIdentifiers where identifiers.contains(iapIdentifier) {
                return true
            }
            return false
        } else {
            return isPlanWithFollowingDetailsPresentInIAPIdentifierList(name: protonPlan.name,
                                                                        offer: protonPlan.offer,
                                                                        cycle: protonPlan.cycle,
                                                                        currency: InAppPurchasePlan.defaultCurrency,
                                                                        identifiers: identifiers)
        }
    }

    struct InAppPurchaseIdentifierParsingResults {
        let storeKitProductId: String
        let protonPlanName: String
        let offerName: String?
        let period: String
        let currency: String
    }

    private static func extractPlanDetails(from storeKitProductId: String) -> InAppPurchaseIdentifierParsingResults? {
        guard let result = regex.firstMatch(in: storeKitProductId, options: [], range: NSRange(location: 0, length: storeKitProductId.count)),
              // five ranges, because there are 4 capture groups in regex plus the first range is always for the whole string (implicit whole match capture group)
              result.numberOfRanges == 5,
              // range 1 is for the plan name capture group
              result.range(at: 1).location != NSNotFound,
              result.range(at: 1).length != 0,
              // range 2 is for the offer name capture group — it should always be there, but it might be of zero length if IAP is not representing the offer
              result.range(at: 2).location != NSNotFound,
              // range 3 is for the cycle capture group
              result.range(at: 3).location != NSNotFound,
              result.range(at: 3).length != 0,
              // range 4 is for the currency
              result.range(at: 4).location != NSNotFound,
              result.range(at: 4).length != 0
        else { return nil }
        let protonName = NSString(string: storeKitProductId).substring(with: result.range(at: 1))
        let offer: String?
        // if the offer name range is not empty, it means we captured the offer name and we can expose it further
        if result.range(at: 2).length != 0 {
            offer = NSString(string: storeKitProductId).substring(with: result.range(at: 2))
        } else {
            offer = nil
        }
        let period = NSString(string: storeKitProductId).substring(with: result.range(at: 3))
        let currency = NSString(string: storeKitProductId).substring(with: result.range(at: 4))
        return InAppPurchaseIdentifierParsingResults(storeKitProductId: storeKitProductId,
                                                     protonPlanName: protonName,
                                                     offerName: offer,
                                                     period: period,
                                                     currency: currency)
    }

    private static func isPlanWithFollowingDetailsPresentInIAPIdentifierList(
        name: String, offer: String?, cycle: Int?, currency: String?, identifiers: ListOfIAPIdentifiers
    ) -> Bool {
        guard !name.isEmpty else { return false }
        let iapPlan = InAppPurchasePlan(protonPlanName: name, offer: offer, listOfIAPIdentifiers: identifiers)
        return iapPlan.storeKitProductId != nil && iapPlan.period == cycle.map(String.init) && iapPlan.currency?.lowercased() == currency?.lowercased()
    }

    /// Given a Plan and a list of App Store product ids,
    /// it will create an InAppPurchasePlan whose cycle
    /// coincides with the one in the Plan if there's a
    /// product id with the same cycle component, and same
    /// Proton plan name (i.e. `bundle2022`), and
    /// offer, period and currency extracted from the product id components
    public init?(protonPlan: Plan, listOfIAPIdentifiers: ListOfIAPIdentifiers) {
        guard !protonPlan.name.isEmpty else { return nil }
        if let vendorIAPs = protonPlan.vendors?.apple.plans {
            let matchingPlanDetails = vendorIAPs
                .map { cycle, iapIdentifier in (cycle, InAppPurchasePlan.extractPlanDetails(from: iapIdentifier)) }
                .filter { cycle, identifiedPlanDetails in cycle == identifiedPlanDetails?.period }
                .compactMap { $0.1 }
                .first
            guard let matchingPlanDetails, matchingPlanDetails.protonPlanName == protonPlan.name else { return nil }
            self.init(storeKitProductId: matchingPlanDetails.storeKitProductId,
                      protonName: protonPlan.name,
                      offer: matchingPlanDetails.offerName,
                      period: matchingPlanDetails.period,
                      currency: matchingPlanDetails.currency)
        } else {
            self.init(protonPlanName: protonPlan.name, offer: protonPlan.offer, listOfIAPIdentifiers: listOfIAPIdentifiers)
        }
    }

    /// Creates an InAppPurchasePlan from the corresponding components in the product id:
    /// plan name, offer, period and currency
    public init?(storeKitProductId: ProductId,
                 featureFlagsRepository: FeatureFlagsRepositoryProtocol = FeatureFlagsRepository.shared) {
        if featureFlagsRepository.isEnabled(CoreFeatureFlagType.dynamicPlan)  {
            self.init(storeKitProductId: storeKitProductId,
                      protonName: storeKitProductId, // only used for observability to find if it's the free plan
                      offer: nil,
                      period: nil,
                      currency: "USD")
        } else {
            guard let matchingPlanDetails = InAppPurchasePlan.extractPlanDetails(from: storeKitProductId) else { return nil }
            self.init(storeKitProductId: matchingPlanDetails.storeKitProductId,
                      protonName: matchingPlanDetails.protonPlanName,
                      offer: matchingPlanDetails.offerName,
                      period: matchingPlanDetails.period,
                      currency: matchingPlanDetails.currency)
        }
    }

    /// Creates an InAppPurchasePlan from an Instance's Product Id corresponding components
    public init?(availablePlanInstance: AvailablePlans.AvailablePlan.Instance) {
        guard let iapIdentifier = availablePlanInstance.vendors?.apple.productID else {
            return nil
        }
        self.init(storeKitProductId: iapIdentifier)
        self.period = availablePlanInstance.cycle.description
    }

    /// Creates an InAppPurchasePlan with a Proton plan name, an offer if present,
    /// and a list of Product Ids, picking the first product id that matches
    /// the proton plan name (if possible, otherwise the passed one),
    /// the offer (if possible), the cycle and the currency (if they exist)
    private init(protonPlanName: String, offer: String?, listOfIAPIdentifiers: ListOfIAPIdentifiers) {
        let matchingPlanDetails = listOfIAPIdentifiers
            .compactMap(InAppPurchasePlan.extractPlanDetails(from:))
            .first {
                if let offer, offer != InAppPurchasePlan.defaultOffer {
                    return $0.protonPlanName == protonPlanName && $0.offerName == offer
                } else {
                    return $0.protonPlanName == protonPlanName && $0.offerName == nil
                }

            }
        self.init(storeKitProductId: matchingPlanDetails?.storeKitProductId,
                  protonName: matchingPlanDetails?.protonPlanName ?? protonPlanName,
                  offer: matchingPlanDetails?.offerName,
                  period: matchingPlanDetails?.period,
                  currency: matchingPlanDetails?.currency)
    }

    private init(storeKitProductId: InAppPurchasePlan.ProductId?,
                 protonName: String,
                 offer: String?,
                 period: String?,
                 currency: String?) {
        self.storeKitProductId = storeKitProductId
        self.protonName = protonName
        self.offer = offer
        self.period = period
        self.currency = currency
    }
}
