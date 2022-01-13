//
//  SignInMock.swift
//  ProtonCore-Login - Created on 05/11/2020.
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

import ProtonCore_DataModel
import ProtonCore_Networking
import ProtonCore_Services
#if canImport(Crypto_VPN)
import Crypto_VPN
#elseif canImport(Crypto)
import Crypto
#endif
import ProtonCore_Login

public class LoginMock: Login {
    
    public init() {}

    public let signUpDomain: String = "protonmail.com"

    public func checkAvailability(username: String, completion: @escaping (Result<(), AvailabilityError>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(.success)
        }
    }
    
    public func checkAvailabilityExternal(email: String, completion: @escaping (Result<(), AvailabilityError>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(.success)
        }
    }

    public func setUsername(username: String, completion: @escaping (Result<(), SetUsernameError>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(.failure(.alreadySet(message: "Already set")))
        }
    }

    public func createAddress(completion: @escaping (Result<Address, CreateAddressError>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(.failure(.generic(message: "", code: 0)))
        }
    }

    public func logout(credential: AuthCredential, completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(.success)
        }
    }

    public func login(username: String, password: String, completion: @escaping (Result<LoginStatus, LoginError>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(.failure(.generic(message: "", code: 0)))
        }
    }

    public func provide2FACode(_ code: String, completion: @escaping (Result<LoginStatus, LoginError>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(.failure(.generic(message: "", code: 0)))
        }
    }

    public func finishLoginFlow(mailboxPassword: String, completion: @escaping (Result<LoginStatus, LoginError>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(.failure(.generic(message: "", code: 0)))
        }
    }

    public func createAccountKeysIfNeeded(user: User, addresses: [Address]?, mailboxPassword: String?, completion: @escaping (Result<User, LoginError>) -> Void) {

    }

    public func createAddressKeys(user: User, address: Address, mailboxPassword: String, completion: @escaping (Result<Key, CreateAddressKeysError>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(.failure(.generic(message: "", code: 0)))
        }
    }
    
    public var minimumAccountType: AccountType {
        return .username
    }

    public func updateAccountType(accountType: AccountType) {

    }

    public func updateAvailableDomain(type: AvailableDomainsType, result: @escaping (String?) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            result("")
        }
    }
    
    public func refreshCredentials(completion: @escaping (Result<Credential, LoginError>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(.failure(.generic(message: "", code: 0)))
        }
    }
    
    public func refreshUserInfo(completion: @escaping (Result<User, LoginError>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(.failure(.generic(message: "", code: 0)))
        }
    }
    
    public var startGeneratingAddress: (() -> Void)?
    
    public var startGeneratingKeys: (() -> Void)?
}

public class AnonymousServiceManager: APIServiceDelegate {
    
    public init() {}
    
    public var locale: String { return "en_US" }
    public var appVersion: String = "iOSMail_2.7.0"
    public var userAgent: String?
    public func onUpdate(serverTime: Int64) {
        CryptoUpdateTime(serverTime)
    }
    public func isReachable() -> Bool { return true }
    public func onDohTroubleshot() { }
    public func onHumanVerify() { }
    public func onChallenge(challenge: URLAuthenticationChallenge, credential: AutoreleasingUnsafeMutablePointer<URLCredential?>?) -> URLSession.AuthChallengeDisposition {
        let dispositionToReturn: URLSession.AuthChallengeDisposition = .performDefaultHandling
        return dispositionToReturn
    }
}

public class AnonymousAuthManager: AuthDelegate {
    
    public init() {}
    
    public var authCredential: AuthCredential?

    public func getToken(bySessionUID uid: String) -> AuthCredential? {
        return self.authCredential
    }
    public func onLogout(sessionUID uid: String) { }
    public func onUpdate(auth: Credential) {
        self.authCredential = AuthCredential( auth)
    }
    public func onRefresh(bySessionUID uid: String, complete: (Credential?, AuthErrors?) -> Void) { }
    public func onForceUpgrade() { }
}
