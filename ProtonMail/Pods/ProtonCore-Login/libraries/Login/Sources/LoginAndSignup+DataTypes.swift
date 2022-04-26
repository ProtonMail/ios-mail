//
//  LoginAndSignup+DataTypes.swift
//  ProtonCore-Login - Created on 27/05/2021.
//
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
import ProtonCore_DataModel
import ProtonCore_Networking

public enum AccountType {
    case `internal`
    case external
    case username
}

public enum LoginData {
    case credential(Credential)
    case userData(UserData)
}

public extension LoginData {
    
    var credential: Credential {
        switch self {
        case .userData(let userData): return Credential(userData.credential, scope: userData.scopes)
        case .credential(let credential): return credential
        }
    }
    
    func updated(credential: Credential) -> LoginData {
        switch self {
        case .credential:
            return .credential(credential)
        case .userData(let userData):
            return .userData(UserData(credential: userData.credential.updatedKeepingKeyAndPasswordDataIntact(credential: credential),
                                      user: userData.user,
                                      salts: userData.salts,
                                      passphrases: userData.passphrases,
                                      addresses: userData.addresses,
                                      scopes: credential.scope))
        }
    }
    
    func updated(user: User) -> LoginData {
        switch self {
        case .credential: return self
        case .userData(let userData):
            return .userData(UserData(credential: userData.credential,
                                      user: user,
                                      salts: userData.salts,
                                      passphrases: userData.passphrases,
                                      addresses: userData.addresses,
                                      scopes: userData.scopes))
        }
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
                 weekStart: nil,
                 delaySendSeconds: nil)
    }
}

public enum LoginResult {
    case dismissed
    case loggedIn(LoginData)
    case signedUp(LoginData)
}
