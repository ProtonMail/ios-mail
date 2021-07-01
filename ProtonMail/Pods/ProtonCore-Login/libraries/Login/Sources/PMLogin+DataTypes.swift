//
//  PMLogin+DataTypes.swift
//  ProtonCore-Login
//
//  Created by Krzysztof Siejkowski on 27/05/2021.
//

import Foundation
import ProtonCore_DataModel
import ProtonCore_Networking

public enum AccountType {
    case `internal`
    case external
    case username
}

public struct LoginData {
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

public enum SignupMode: Equatable {
    case notAvailable
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
