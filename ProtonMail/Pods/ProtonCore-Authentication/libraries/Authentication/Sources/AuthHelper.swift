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
import ProtonCore_Log
import ProtonCore_Utilities
import ProtonCore_Networking
import ProtonCore_Services

public protocol AuthHelperDelegate: AnyObject {
    // if credentials are persisted, this is the place to persist new ones
    func credentialsWereUpdated(authCredential: AuthCredential, credential: Credential, for sessionUID: String)
    // if credentials are persisted, this is the place to clear credentials
    func sessionWasInvalidated(for sessionUID: String)
}

public final class AuthHelper: AuthDelegate {
    
    private let authCredentials: Atomic<(AuthCredential, Credential)?>
    private weak var delegate: AuthHelperDelegate?
    
    private var delegateExecutor: CompletionBlockExecutor!
    
    public init(authCredential: AuthCredential) {
        let credential = Credential(authCredential)
        self.authCredentials = .init((authCredential, credential))
    }
    
    public init(credential: Credential) {
        let authCredential = AuthCredential(credential)
        self.authCredentials = .init((authCredential, credential))
    }
    
    public init() {
        self.authCredentials = .init(nil)
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
        self.authCredentials = .init(initialBothCredentials)
    }
    
    public func setUpDelegate(_ delegate: AuthHelperDelegate, callingItOn executor: CompletionBlockExecutor? = nil) {
        if let executor = executor {
            self.delegateExecutor = executor
        } else {
            let dispatchQueue = DispatchQueue(label: "me.proton.core.auth-helper.default", qos: .userInitiated, attributes: .initiallyInactive)
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
        authCredentials.transform { authCredentials in
            guard let existingCredentials = authCredentials else { return nil }
            guard existingCredentials.0.sessionID == sessionUID else {
                PMLog.error("Asked for wrong credentials. It's a programmers error and should be investigated")
                return nil
            }
            return existingCredentials[keyPath: path]
        }
    }
    
    public func onRefresh(sessionUID: String, service: APIService, complete: @escaping AuthRefreshResultCompletion) {
        guard let oldCredential = authCredentials.transform({ $0?.1 }) else {
            PMLog.error("App tried to refresh non-existing credentials. It's a programmers error and should be investigated")
            complete(.failure(.notImplementedYet("Not logged in")))
            return
        }
        guard oldCredential.UID == sessionUID else {
            PMLog.error("Asked for refreshing credentials of wrong session. It's a programmers error and should be investigated")
            complete(.failure(.notImplementedYet("Wrong session")))
            return
        }
        
        var authenticator: Authenticator? = Authenticator(api: service)
        authenticator?.refreshCredential(oldCredential) { result in
            // captured reference ensures the authenticator is not deallocated until the completion block is called
            authenticator = nil
            switch result {
            case .success(.ask2FA((let newCredential, _))), .success(.newCredential(let newCredential, _)), .success(.updatedCredential(let newCredential)):
                complete(.success(newCredential))
            case .failure(let authError):
                complete(.failure(authError))
            }
        }
    }
    
    public func onUpdate(credential: Credential, sessionUID: String) {
        authCredentials.mutate { credentialsToBeUpdated in
            
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
            
            guard let delegate = delegate else { return }
            delegateExecutor.execute {
                delegate.credentialsWereUpdated(authCredential: updatedAuth, credential: updatedCredentials, for: sessionUID)
            }
        }
    }
    
    public func onAuthentication(credential: Credential, service: APIService?) {
        authCredentials.mutate { authCredentials in
            
            let sessionUID = credential.UID
            let newCredentials = (AuthCredential(credential), credential)
            
            service?.setSessionUID(uid: sessionUID)
            authCredentials = newCredentials
            
            guard let delegate = delegate else { return }
            delegateExecutor.execute {
                delegate.credentialsWereUpdated(authCredential: newCredentials.0, credential: newCredentials.1, for: sessionUID)
            }
        }
    }
    
    public func updateAuth(for sessionUID: String, password: String?, salt: String?, privateKey: String?) {
        authCredentials.mutate { authCredentials in
            guard authCredentials != nil else { return }
            guard authCredentials?.0.sessionID == sessionUID else {
                PMLog.error("Asked for updating credentials of a wrong session. It's a programmers error and should be investigated")
                return
            }

            if let password = password {
                authCredentials?.0.udpate(password: password)
            }
            let saltToUpdate = salt ?? authCredentials?.0.passwordKeySalt
            let privateKeyToUpdate = privateKey ?? authCredentials?.0.privateKey
            authCredentials?.0.update(salt: saltToUpdate, privateKey: privateKeyToUpdate)
            
            guard let delegate = delegate, let existingCredentials = authCredentials else { return }
            delegateExecutor.execute {
                delegate.credentialsWereUpdated(authCredential: existingCredentials.0, credential: existingCredentials.1, for: sessionUID)
            }
        }
    }
    
    public func onLogout(sessionUID: String) {
        authCredentials.mutate { authCredentials in
            guard let existingCredentials = authCredentials else { return }
            guard existingCredentials.0.sessionID == sessionUID else {
                PMLog.error("Asked for logout of wrong session. It's a programmers error and should be investigated")
                return
            }
            authCredentials = nil
            
            guard let delegate = delegate else { return }
            delegateExecutor.execute {
                delegate.sessionWasInvalidated(for: sessionUID)
            }
        }
    }
}
    
extension AuthHelper {
    
    @available(*, deprecated, message: "Please use onUpdate(credential:sessionUID:) instead")
    public func onUpdate(auth: Credential) {
        assertionFailure("Should never be called")
    }
    
    @available(*, deprecated, message: "Please use onRefresh(sessionUID:for:complete:) instead")
    public func onRefresh(bySessionUID sessionUID: String, complete: @escaping AuthRefreshComplete) {
        assertionFailure("Should never be called")
    }
}
