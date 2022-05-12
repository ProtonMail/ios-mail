//
//  AuthManager.swift
//  ProtonCore-Login - Created on 11.12.2020.
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
import ProtonCore_Networking
import ProtonCore_Services

public final class AuthManager: AuthDelegate {
    private var authCredential: AuthCredential?
    private(set) var scopes: [String]?
    
    public init() {}

    func setCredential(auth: Credential) {
        authCredential = authCredential?.updatedKeepingKeyAndPasswordDataIntact(credential: auth) ?? AuthCredential(auth)
        scopes = auth.scope
    }

    func updateAuth(password: String?, salt: String?, privateKey: String?) {
        if let password = password {
            authCredential?.udpate(password: password)
        }
        let saltToUpdate = salt ?? authCredential?.passwordKeySalt
        let privateKeyToUpdate = privateKey ?? authCredential?.privateKey
        authCredential?.update(salt: saltToUpdate, privateKey: privateKeyToUpdate)
    }

    public func getToken(bySessionUID uid: String) -> AuthCredential? {
        authCredential
    }

    public func onLogout(sessionUID uid: String) { }

    public func onUpdate(auth: Credential) {
        authCredential = authCredential?.updatedKeepingKeyAndPasswordDataIntact(credential: auth) ?? AuthCredential(auth)
        if !auth.scope.isEmpty {
            // if there's no update in scopes, assume the same scope as previously
            scopes = auth.scope
        }
    }

    public func onRefresh(bySessionUID uid: String, complete: @escaping AuthRefreshComplete) {
        complete(nil, nil)
    }

    func onForceUpgrade() { }
}
