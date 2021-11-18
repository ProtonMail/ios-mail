//
//  LoginAndSignup+DataTypes.swift
//  ProtonCore-Login - Created on 27/05/2021.
//
//
//  Copyright (c) 2021 Proton Technologies AG
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
import ProtonCore_DataModel
import ProtonCore_Networking
import ProtonCore_Payments

public enum AccountType {
    case `internal`
    case external
    case username
}

public enum LoginData {
    case credential(Credential)
    case userData(UserData)
}

public struct UserData {
    public let credential: AuthCredential
    public let user: User
    public let salts: [KeySalt]
    public let passphrases: [String: String]
    public let addresses: [Address]
    public let scopes: [String]

    public init(credential: AuthCredential,
                user: User,
                salts: [KeySalt],
                passphrases: [String: String],
                addresses: [Address],
                scopes: [String]) {
        self.credential = credential
        self.user = user
        self.salts = salts
        self.passphrases = passphrases
        self.addresses = addresses
        self.scopes = scopes
    }

    public var toUserInfo: UserInfo {
        UserInfo(displayName: user.displayName,
                 maxSpace: Int64(user.maxSpace),
                 notificationEmail: nil,
                 signature: nil,
                 usedSpace: Int64(user.usedSpace),
                 userAddresses: addresses,
                 autoSC: nil,
                 language: nil,
                 maxUpload: Int64(user.maxUpload),
                 notify: nil,
                 showImage: nil,
                 swipeL: nil,
                 swipeR: nil,
                 role: user.role,
                 delinquent: user.delinquent,
                 keys: user.keys,
                 userId: user.ID,
                 sign: nil,
                 attachPublicKey: nil,
                 linkConfirmation: nil,
                 credit: user.credit,
                 currency: user.currency,
                 pwdMode: nil,
                 twoFA: nil,
                 enableFolderColor: nil,
                 inheritParentFolderColor: nil,
                 subscribed: user.subscribed,
                 groupingMode: nil,
                 weekStart: nil)
    }
}

public enum LoginResult {
    case dismissed
    case loggedIn(LoginData)
}

public enum SignupInitalMode {
    case `internal`
    case external
}

public enum LoginFeatureAvailability<Parameters> {
    case notAvailable
    case available(parameters: Parameters)
    
    public var isNotAvailable: Bool {
        if case .notAvailable = self { return true }
        return false
    }
}

public typealias SignupAvailability = LoginFeatureAvailability<SignupParameters>

public struct SignupParameters {
    
    let mode: SignupMode
    let passwordRestrictions: SignupPasswordRestrictions
    let summaryScreenVariant: SummaryScreenVariant
    
    public init(mode: SignupMode, passwordRestrictions: SignupPasswordRestrictions, summaryScreenVariant: SummaryScreenVariant) {
        self.mode = mode
        self.passwordRestrictions = passwordRestrictions
        self.summaryScreenVariant = summaryScreenVariant
    }
}

public enum SignupMode: Equatable {
    case `internal`
    case external
    case both(initial: SignupInitalMode)
}

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
    var reportBugAlertHandler: BugAlertHandler
    
    public init(listOfIAPIdentifiers: ListOfIAPIdentifiers, reportBugAlertHandler: BugAlertHandler) {
        self.listOfIAPIdentifiers = listOfIAPIdentifiers
        self.reportBugAlertHandler = reportBugAlertHandler
    }
}
