//
//  LoginAndSignup+DataTypes.swift
//  ProtonCore-Login - Created on 27/05/2021.
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

#if os(iOS)

import Foundation
import ProtonCoreLogin
import ProtonCoreDataModel
import ProtonCoreNetworking
import ProtonCorePayments
import ProtonCorePaymentsUI

@available(*, deprecated, message: "SignupMode is deprecated")
public enum SignupMode: Equatable {
    case `internal`
    case external
    case both(initial: SignupInitialMode)
}

@available(*, deprecated, message: "SignupInitialMode is deprecated")
public enum SignupInitialMode {
    case `internal`
    case external
}

public enum LoginFeatureAvailability<Parameters> {
    case notAvailable
    case available(parameters: Parameters)

    var isAvailable: Bool {
        if case .available = self { return true }
        return false
    }
}

public typealias SignupAvailability = LoginFeatureAvailability<SignupParameters>

public struct SignupParameters {

    let separateDomainsButton: Bool
    let passwordRestrictions: SignupPasswordRestrictions
    let summaryScreenVariant: SummaryScreenVariant

    public init(separateDomainsButton: Bool,
                passwordRestrictions: SignupPasswordRestrictions,
                summaryScreenVariant: SummaryScreenVariant) {
        self.separateDomainsButton = separateDomainsButton
        self.passwordRestrictions = passwordRestrictions
        self.summaryScreenVariant = summaryScreenVariant
    }
}

@available(*, deprecated, message: "SignupPasswordRestrictions is deprecated. Use PasswordRestrictions in ProtonCore-Utilities")
public struct SignupPasswordRestrictions: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let notEmpty                   = SignupPasswordRestrictions(rawValue: 1 << 0)
    public static let atLeastEightCharactersLong = SignupPasswordRestrictions(rawValue: 1 << 1)

    public static let `default`: SignupPasswordRestrictions = [.atLeastEightCharactersLong, .notEmpty]

    public func failedRestrictions(for password: String) -> SignupPasswordRestrictions {
        var failedRestrictions: SignupPasswordRestrictions = []
        if contains(.notEmpty) && password.isEmpty {
            failedRestrictions.insert(.notEmpty)
        }
        if contains(.atLeastEightCharactersLong) && password.count < 8 {
            failedRestrictions.insert(.atLeastEightCharactersLong)
        }
        return failedRestrictions
    }
}

public typealias PaymentsAvailability = LoginFeatureAvailability<PaymentsParameters>

public struct PaymentsParameters {

    let listOfIAPIdentifiers: ListOfIAPIdentifiers
    let listOfShownPlanNames: ListOfShownPlanNames
    let customPlansDescription: CustomPlansDescription
    var reportBugAlertHandler: BugAlertHandler

    public init(listOfIAPIdentifiers: ListOfIAPIdentifiers,
                listOfShownPlanNames: ListOfShownPlanNames,
                customPlansDescription: CustomPlansDescription = [:],
                reportBugAlertHandler: BugAlertHandler) {
        self.listOfIAPIdentifiers = listOfIAPIdentifiers
        self.listOfShownPlanNames = listOfShownPlanNames
        self.customPlansDescription = customPlansDescription
        self.reportBugAlertHandler = reportBugAlertHandler
    }
}

#endif
