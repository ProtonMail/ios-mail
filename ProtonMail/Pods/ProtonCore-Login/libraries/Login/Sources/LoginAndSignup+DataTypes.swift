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

import Foundation
import ProtonCoreDataModel
import ProtonCoreNetworking

public enum AccountType {
    case `internal`
    case external
    case username
}

public typealias LoginData = UserData

public extension UserData {

    var getCredential: Credential { Credential(credential, scopes: scopes) }

    func updated(credential: Credential) -> UserData {
        UserData(credential: self.credential.updatedKeepingKeyAndPasswordDataIntact(credential: credential),
                 user: user,
                 salts: salts,
                 passphrases: passphrases,
                 addresses: addresses,
                 scopes: credential.scopes)
    }

    func updated(user: User) -> UserData {
        UserData(credential: credential,
                 user: user,
                 salts: salts,
                 passphrases: passphrases,
                 addresses: addresses,
                 scopes: scopes)
    }
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
                 hideEmbeddedImages: nil,
                 hideRemoteImages: nil,
                 imageProxy: nil,
                 maxSpace: Int64(user.maxSpace),
                 notificationEmail: nil,
                 signature: nil,
                 usedSpace: Int64(user.usedSpace),
                 userAddresses: addresses,
                 autoSC: nil,
                 language: nil,
                 maxUpload: Int64(user.maxUpload),
                 notify: nil,
                 swipeLeft: nil,
                 swipeRight: nil,
                 role: user.role,
                 delinquent: user.delinquent,
                 keys: user.keys,
                 userId: user.ID,
                 sign: nil,
                 attachPublicKey: nil,
                 linkConfirmation: nil,
                 credit: user.credit,
                 currency: user.currency,
                 createTime: user.createTimeIntervalSince1970,
                 pwdMode: nil,
                 twoFA: nil,
                 enableFolderColor: nil,
                 inheritParentFolderColor: nil,
                 subscribed: user.subscribed,
                 groupingMode: nil,
                 weekStart: nil,
                 delaySendSeconds: nil,
                 telemetry: nil,
                 crashReports: nil,
                 conversationToolbarActions: nil,
                 messageToolbarActions: nil,
                 listToolbarActions: nil,
                 referralProgram: nil
        )
    }
}

private extension User {
    var createTimeIntervalSince1970: Int64? {
        guard let createTime else { return nil }
        return Int64(createTime)
    }
}

// API that doesn't return data as soon as possible
public enum LoginResult {
    case dismissed
    case loggedIn(LoginData)
    case signedUp(LoginData)
}

// API that returns data as soon as possible
public enum LoginState {
    case dataIsAvailable(LoginData)
    case loginFinished
}

public enum SignupState {
    case dataIsAvailable(LoginData)
    case signupFinished
}

public enum LoginAndSignupResult {
    case dismissed
    case loginStateChanged(LoginState)
    case signupStateChanged(SignupState)
}
