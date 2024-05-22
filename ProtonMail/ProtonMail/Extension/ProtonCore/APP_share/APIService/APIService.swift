//
//  APIService.swift
//  Proton Mail
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import CoreData
import ProtonCoreAuthentication
import ProtonCoreChallenge
import ProtonCoreEnvironment
import ProtonCoreLog
import ProtonCoreKeymaker
import ProtonCoreNetworking
import ProtonCoreServices
import ProtonMailAnalytics
import UIKit

extension PMAPIService {
    private static let dispatchQueue = DispatchQueue(label: "ch.protonmail.PMAPIService.unauthorized")
    private static var _unauthorized: PMAPIService?
    private static var _authManagerForUnauthorizedAPIService: AuthManagerForUnauthorizedAPIService?

    static func unauthorized(dependencies: AuthManagerForUnauthorizedAPIService.Dependencies) -> PMAPIService {
        dispatchQueue.sync {
            if let _unauthorized {
                return _unauthorized
            }
            let authManagerForUnauthorizedAPIService = AuthManagerForUnauthorizedAPIService(dependencies: dependencies)

            let unauthorized: PMAPIService
            if let initialSessionUID = authManagerForUnauthorizedAPIService.initialSessionUID {
                unauthorized = PMAPIService.createAPIService(
                    environment: BackendConfiguration.shared.environment,
                    sessionUID: initialSessionUID,
                    challengeParametersProvider: .forAPIService(clientApp: .mail, challenge: PMChallenge())
                )
            } else {
                unauthorized = PMAPIService.createAPIServiceWithoutSession(
                    environment: BackendConfiguration.shared.environment,
                    challengeParametersProvider: .forAPIService(clientApp: .mail, challenge: PMChallenge())
                )
            }
#if !APP_EXTENSION
            unauthorized.serviceDelegate = PMAPIService.ServiceDelegate.shared
            unauthorized.humanDelegate = HumanVerificationManager.shared.humanCheckHelper(apiService: unauthorized)
            unauthorized.forceUpgradeDelegate = ForceUpgradeManager.shared.forceUpgradeHelper
#endif
            unauthorized.authDelegate = authManagerForUnauthorizedAPIService.authDelegateForUnauthorized
            _unauthorized = unauthorized
            _authManagerForUnauthorizedAPIService = authManagerForUnauthorizedAPIService
            return unauthorized
        }
    }

    static func setupTrustIfNeeded() {
//        #if DEBUG
//        PMAPIService.noTrustKit = true
//        #endif

        guard PMAPIService.trustKit == nil else { return }
        #if !APP_EXTENSION
        // For the extension, please check ShareExtensionEntry
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            assertionFailure(
                "\(UIApplication.shared.delegate.map { "\($0)" } ?? "null") is not an instance of AppDelegate!"
            )
            return
        }
        TrustKitWrapper.start(delegate: delegate)
        #endif
    }
}

final class AuthManagerForUnauthorizedAPIService: AuthHelperDelegate {
    typealias Dependencies = HasKeychain & HasKeyMakerProtocol & HasUserDefaults

    private let key = "Unauthenticated_session"

    let initialSessionUID: String?

    let authDelegateForUnauthorized: AuthHelper
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        defer {
            let redactedSessionID = initialSessionUID?.redacted ?? ""
            Breadcrumbs.shared.add(message: "AuthManagerForUnauthorizedAPIService sessionID=\(redactedSessionID)", to: .randomLogout)
            let dispatchQueue = DispatchQueue(label: "me.proton.mail.queue.unauth-session-auth-helper-delegate")
            authDelegateForUnauthorized.setUpDelegate(self, callingItOn: .asyncExecutor(dispatchQueue: dispatchQueue))
        }

        guard let mainKey = dependencies.keyMaker.mainKey(by: dependencies.keychain.randomPinProtection),
              let data = dependencies.userDefaults.data(forKey: key) else {
            self.authDelegateForUnauthorized = AuthHelper()
            self.initialSessionUID = nil
            return
        }

        let authUnlockedNSCoding = try? Locked<[AuthCredential]>(encryptedValue: data).unlock(with: mainKey).first

        guard let authCredential = authUnlockedNSCoding else {
            dependencies.userDefaults.remove(forKey: key)
            self.authDelegateForUnauthorized = AuthHelper()
            self.initialSessionUID = nil
            return
        }

        self.authDelegateForUnauthorized = AuthHelper(authCredential: authCredential)
        self.initialSessionUID = authCredential.sessionID
    }

    func credentialsWereUpdated(authCredential: AuthCredential, credential _: Credential, for _: String) {
        guard let mainKey = dependencies.keyMaker.mainKey(by: dependencies.keychain.randomPinProtection),
              let lockedAuth = try? Locked<[AuthCredential]>(clearValue: [authCredential], with: mainKey) else { return }
        dependencies.userDefaults.setValue(lockedAuth.encryptedValue, forKey: key)
        SystemLogger.log(message: "unauthorized session was updated.", category: .unauthorizedSession)
    }

    func sessionWasInvalidated(for _: String, isAuthenticatedSession: Bool) {
        SystemLogger.log(message: "unauthorized session was invalidated.", category: .unauthorizedSession)
        dependencies.userDefaults.remove(forKey: key)
    }
}

extension PMAPIService {
    final class ServiceDelegate: APIServiceDelegate {
        static let shared = ServiceDelegate()

        var appVersion: String {
            Constants.App.appVersion
        }

        var userAgent: String? {
            UserAgent.default.ua
        }

        var locale: String {
            Locale.autoupdatingCurrent.identifier
        }

        var additionalHeaders: [String : String]? {
            nil
        }

        func onUpdate(serverTime: Int64) {
            MailCrypto.updateTime(serverTime, processInfo: userCachedStatus)
        }

        func isReachable() -> Bool {
            InternetConnectionStatusProvider.shared.status.isConnected
        }

        func onDohTroubleshot() {
        }
    }
}
