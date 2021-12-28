//
//  AccountPlan.swift
//  ProtonCore-Payments - Created on 30/11/2020.
//
//  Copyright (c) 2019 Proton Technologies AG
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

public typealias ListOfIAPIdentifiers = Set<String>
public typealias ListOfShownPlanNames = Set<String>

@available(*, deprecated, renamed: "InAppPurchasePlan")
public typealias AccountPlan = InAppPurchasePlan

public struct InAppPurchasePlan: Equatable, Hashable {

    public typealias ProductId = String

    public let protonName: String
    public let storeKitProductId: ProductId?
    public let period: String?

    public var isFreePlan: Bool { InAppPurchasePlan.isThisAFreePlan(protonName: protonName) }

    public static let freePlanName = "free"

    public static func isThisAFreePlan(protonName: String) -> Bool {
        protonName == freePlanName || protonName == "vpnfree" || protonName == "drivefree"
    }

    public static func isThisATrialPlan(protonName: String) -> Bool {
        protonName == "trial"
    }

    private static let regex: NSRegularExpression = {
        guard let instance = try? NSRegularExpression(pattern: "^ios.*_(.*)_(\\d+)_\\w+_non_renewing$", options: [.anchorsMatchLines]) else {
            assertionFailure("The regular expression was not compiled right")
            return NSRegularExpression()
        }
        return instance
    }()

    public static func protonNameAndPeriod(from storeKitProductId: ProductId) -> (String, String)? {
        guard let result = regex.firstMatch(in: storeKitProductId, options: [], range: NSRange(location: 0, length: storeKitProductId.count)),
              result.numberOfRanges == 3,
              result.range(at: 1).location != NSNotFound,
              result.range(at: 1).length != 0,
              result.range(at: 2).location != NSNotFound,
              result.range(at: 2).length != 0
        else { return nil }
        let protonName = NSString(string: storeKitProductId).substring(with: result.range(at: 1))
        let period = NSString(string: storeKitProductId).substring(with: result.range(at: 2))
        return (protonName, period)
    }

    public static func nameIsPresentInIAPIdentifierList(name: String, identifiers: ListOfIAPIdentifiers) -> Bool {
        InAppPurchasePlan(protonName: name, listOfIAPIdentifiers: identifiers)?.storeKitProductId != nil
    }

    public init?(protonName: String, listOfIAPIdentifiers: ListOfIAPIdentifiers) {
        guard !protonName.isEmpty else { return nil }
        self.init(protonPlanName: protonName, listOfIAPIdentifiers: listOfIAPIdentifiers)
    }

    private init(protonPlanName: String, listOfIAPIdentifiers: ListOfIAPIdentifiers) {
        self.protonName = protonPlanName
        let extractedData = zip(listOfIAPIdentifiers, listOfIAPIdentifiers.map(InAppPurchasePlan.protonNameAndPeriod(from:)))
            .map { (storeKitProductId: $0.0, extractedProtonName: $0.1) }
            .first { _, extractedProtonName in extractedProtonName?.0 == protonPlanName }
            .map { ($0, $1?.1) }
        self.storeKitProductId = extractedData?.0
        self.period = extractedData?.1
    }

    public init?(storeKitProductId: ProductId) {
        guard let extractedData = InAppPurchasePlan.protonNameAndPeriod(from: storeKitProductId) else { return nil }
        self.storeKitProductId = storeKitProductId
        self.protonName = extractedData.0
        self.period = extractedData.1
    }
}
