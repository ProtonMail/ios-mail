//
//  AuthHelper.swift
//  ProtonCore-Services - Created on 5/22/20.
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

// swiftlint:disable identifier_name todo

import Foundation
import ProtonCoreLog
import ProtonCoreUtilities
import ProtonCoreNetworking
import ProtonCoreServices

public protocol AuthHelperDelegate: AuthSessionInvalidatedDelegate {
    // if credentials are persisted, this is the place to persist new ones
    func credentialsWereUpdated(authCredential: AuthCredential, credential: Credential, for sessionUID: String)
}

public final class AuthHelper: AuthDelegate {
    
    private let currentCredentials: Atomic<(AuthCredential, Credential)?>

    public private(set) weak var delegate: AuthHelperDelegate?
    public weak var authSessionInvalidatedDelegateForLoginAndSignup: AuthSessionInvalidatedDelegate?
    private var delegateExecutor: CompletionBlockExecutor?
    
    public init(authCredential: AuthCredential) {
        let credential = Credential(authCredential)
        self.currentCredentials = .init((authCredential, credential))
    }
    
    public init(credential: Credential) {
        let authCredential = AuthCredential(credential)
        self.currentCredentials = .init((authCredential, credential))
    }
    
    public init() {
        self.currentCredentials = .init(nil)
    }
    
    public init?(initialBothCredentials: (AuthCredential, Credential)) {
        let authCredential = initialBothCredentials.0
        let credential = initialBothCredentials.1
        guard authCredential.sessionID == credential.UID,
              authCredential.accessToken == credential.accessToken,
              authCredential.refreshToken == credential.refreshToken,
              authCredential.userID == credential.userID,
              authCredential.userName == credential.userName else {
            return nil
        }
        self.currentCredentials = .init(initialBothCredentials)
    }
    
    public func setUpDelegate(_ delegate: AuthHelperDelegate, callingItOn executor: CompletionBlockExecutor? = nil) {
        if let executor = executor {
            self.delegateExecutor = executor
        } else {
            let dispatchQueue = DispatchQueue(label: "me.proton.core.auth-helper.default", qos: .userInitiated)
            self.delegateExecutor = .asyncExecutor(dispatchQueue: dispatchQueue)
        }
        self.delegate = delegate
    }

    public func credential(sessionUID: String) -> Credential? {
        fetchCredentials(for: sessionUID, path: \.1)
    }
    
    public func authCredential(sessionUID: String) -> AuthCredential? {
        fetchCredentials(for: sessionUID, path: \.0)
    }
    
    private func fetchCredentials<T>(for sessionUID: String, path: KeyPath<(AuthCredential, Credential), T>) -> T? {
        currentCredentials.transform { authCredentials in
            guard let existingCredentials = authCredentials else { return nil }
            guard existingCredentials.0.sessionID == sessionUID else {
                PMLog.error("Asked for wrong credentials. It's a programmers error and should be investigated")
                return nil
            }
            return existingCredentials[keyPath: path]
        }
    }

    public func onUpdate(credential: Credential, sessionUID: String) {
        currentCredentials.mutate { credentialsToBeUpdated in
            
            guard let existingCredentials = credentialsToBeUpdated else {
                credentialsToBeUpdated = (AuthCredential(credential), credential)
                return
            }
            
            guard existingCredentials.0.sessionID == sessionUID else {
                PMLog.error("Asked for updating credentials of a wrong session. It's a programmers error and should be investigated")
                return
            }
            
            // we don't nil out the key and password to avoid loosing this information unintentionaly
            let updatedAuth = existingCredentials.0.updatedKeepingKeyAndPasswordDataIntact(credential: credential)
            var updatedCredentials = credential
            
            // if there's no update in scopes, assume the same scope as previously
            if updatedCredentials.scopes.isEmpty {
                updatedCredentials.scopes = existingCredentials.1.scopes
            }

            credentialsToBeUpdated = (updatedAuth, updatedCredentials)
            
            guard let delegate, let delegateExecutor else { return }
            delegateExecutor.execute {
                delegate.credentialsWereUpdated(authCredential: updatedAuth, credential: updatedCredentials, for: sessionUID)
            }
        }
    }
    
    public func onSessionObtaining(credential: Credential) {
        currentCredentials.mutate { authCredentials in
            
            let sessionUID = credential.UID
            let newCredentials = (AuthCredential(credential), credential)

            authCredentials = newCredentials
            
            guard let delegate, let delegateExecutor else { return }
            delegateExecutor.execute {
                delegate.credentialsWereUpdated(authCredential: newCredentials.0, credential: newCredentials.1, for: sessionUID)
            }
        }
    }
    
    public func onAdditionalCredentialsInfoObtained(sessionUID: String, password: String?, salt: String?, privateKey: String?) {
        currentCredentials.mutate { authCredentials in
            guard authCredentials != nil else { return }
            guard authCredentials?.0.sessionID == sessionUID else {
                PMLog.error("Asked for updating credentials of a wrong session. It's a programmers error and should be investigated")
                return
            }

            if let password = password {
                authCredentials?.0.update(password: password)
            }
            let saltToUpdate = salt ?? authCredentials?.0.passwordKeySalt
            let privateKeyToUpdate = privateKey ?? authCredentials?.0.privateKey
            authCredentials?.0.update(salt: saltToUpdate, privateKey: privateKeyToUpdate)
            
            guard let delegate, let delegateExecutor, let existingCredentials = authCredentials else { return }
            delegateExecutor.execute {
                delegate.credentialsWereUpdated(authCredential: existingCredentials.0, credential: existingCredentials.1, for: sessionUID)
            }
        }
    }
    
    public func onAuthenticatedSessionInvalidated(sessionUID: String) {
        currentCredentials.mutate { authCredentials in
            guard let existingCredentials = authCredentials else { return }
            guard existingCredentials.0.sessionID == sessionUID else {
                PMLog.error("Asked for logout of wrong session. It's a programmers error and should be investigated")
                return
            }
            authCredentials = nil

            delegateExecutor?.execute { [weak self] in
                self?.delegate?.sessionWasInvalidated(for: sessionUID, isAuthenticatedSession: true)
            }
            authSessionInvalidatedDelegateForLoginAndSignup?.sessionWasInvalidated(for: sessionUID, isAuthenticatedSession: true)
        }
    }

    public func onUnauthenticatedSessionInvalidated(sessionUID: String) {
        currentCredentials.mutate { authCredentials in
            guard let existingCredentials = authCredentials else { return }
            guard existingCredentials.0.sessionID == sessionUID else {
                PMLog.error("Asked for erasing the credentials of a wrong session. It's a programmers error and should be investigated")
                return
            }
            authCredentials = nil

            delegateExecutor?.execute { [weak self] in
                self?.delegate?.sessionWasInvalidated(for: sessionUID, isAuthenticatedSession: false)
            }
            authSessionInvalidatedDelegateForLoginAndSignup?.sessionWasInvalidated(for: sessionUID, isAuthenticatedSession: false)
        }
    }
}
