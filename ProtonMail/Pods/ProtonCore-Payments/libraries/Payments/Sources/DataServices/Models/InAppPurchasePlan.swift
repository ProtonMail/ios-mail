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
import ProtonCore_Utilities

public typealias ListOfIAPIdentifiers = Set<String>
public typealias ListOfShownPlanNames = Set<String>

@available(*, deprecated, renamed: "InAppPurchasePlan")
public typealias AccountPlan = InAppPurchasePlan

public struct InAppPurchasePlan: Equatable, Hashable {
    
    public static let defaultCycle = "12"
    public static let defaultOffer = "default"

    public typealias ProductId = String

    public let storeKitProductId: ProductId?
    public let protonName: String
    public let offer: String?
    public let period: String?

    public var isFreePlan: Bool { InAppPurchasePlan.isThisAFreePlan(protonName: protonName) }
    public var isPlusPlan: Bool { InAppPurchasePlan.isThisAPlusPlan(protonName: protonName) }
    public var isUnlimitedPlan: Bool { InAppPurchasePlan.isThisAUnlimitedPlan(protonName: protonName) }
    
    public static let freePlan: InAppPurchasePlan = .init(protonPlanName: "free", offer: nil, listOfIAPIdentifiers: [])
    public static var freePlanName: String { freePlan.protonName }

    public static func isThisAFreePlan(protonName: String) -> Bool {
        protonName == freePlanName || protonName == "vpnfree" || protonName == "drivefree"
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
            pattern: "^ios[^_]*_([^_]*)_?(.*)_(\\d+)_\\w+_non_renewing(?:_v\\d+)?$",
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
            return isPlanWithFollowingDetailsPresentInIAPIdentifierList(
                name: protonPlan.name, offer: protonPlan.offer, cycle: protonPlan.cycle, identifiers: identifiers
            )
        }
    }
    
    struct InAppPurchaseIdentifierParsingResults {
        let storeKitProductId: String
        let protonPlanName: String
        let offerName: String?
        let period: String
    }
    
    private static func extractPlanDetails(from storeKitProductId: String) -> InAppPurchaseIdentifierParsingResults? {
        guard let result = regex.firstMatch(in: storeKitProductId, options: [], range: NSRange(location: 0, length: storeKitProductId.count)),
              // four ranges, because there are 3 capture groups in regex plus the first range is always for the whole string (implicit whole match capture group)
              result.numberOfRanges == 4,
              // range 1 is for the plan name capture group
              result.range(at: 1).location != NSNotFound,
              result.range(at: 1).length != 0,
              // range 2 is for the offer name capture group — it should always be there, but it might be of zero length if IAP is not representing the offer
              result.range(at: 2).location != NSNotFound,
              // range 3 is for the cycle capture group
              result.range(at: 3).location != NSNotFound,
              result.range(at: 3).length != 0
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
        return InAppPurchaseIdentifierParsingResults(storeKitProductId: storeKitProductId, protonPlanName: protonName, offerName: offer, period: period)
    }
    
    private static func isPlanWithFollowingDetailsPresentInIAPIdentifierList(
        name: String, offer: String?, cycle: Int?, identifiers: ListOfIAPIdentifiers
    ) -> Bool {
        guard !name.isEmpty else { return false }
        let iapPlan = InAppPurchasePlan(protonPlanName: name, offer: offer, listOfIAPIdentifiers: identifiers)
        return iapPlan.storeKitProductId != nil && iapPlan.period == cycle.map(String.init)
    }
    
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
                      period: matchingPlanDetails.period)
        } else {
            self.init(protonPlanName: protonPlan.name, offer: protonPlan.offer, listOfIAPIdentifiers: listOfIAPIdentifiers)
        }
    }
    
    public init?(storeKitProductId: ProductId) {
        guard let extractedData = InAppPurchasePlan.extractPlanDetails(from: storeKitProductId) else { return nil }
        self.init(storeKitProductId: extractedData.storeKitProductId,
                  protonName: extractedData.protonPlanName,
                  offer: extractedData.offerName,
                  period: extractedData.period)
    }

    private init(protonPlanName: String, offer: String?, listOfIAPIdentifiers: ListOfIAPIdentifiers) {
        let extractedData = listOfIAPIdentifiers
            .compactMap(InAppPurchasePlan.extractPlanDetails(from:))
            .first {
                if let offer, offer != InAppPurchasePlan.defaultOffer {
                    return $0.protonPlanName == protonPlanName && $0.offerName == offer
                } else {
                    return $0.protonPlanName == protonPlanName && $0.offerName == nil
                }
            }
        self.init(storeKitProductId: extractedData?.storeKitProductId,
                  protonName: extractedData?.protonPlanName ?? protonPlanName,
                  offer: extractedData?.offerName,
                  period: extractedData?.period)
    }
    
    private init(storeKitProductId: InAppPurchasePlan.ProductId?, protonName: String, offer: String?, period: String?) {
        self.storeKitProductId = storeKitProductId
        self.protonName = protonName
        self.offer = offer
        self.period = period
    }
}
