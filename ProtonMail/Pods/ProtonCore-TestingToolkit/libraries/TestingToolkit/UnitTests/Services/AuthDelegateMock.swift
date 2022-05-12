//
//  AuthDelegateMock.swift
//  ProtonCore-TestingToolkit - Created on 25.04.2022.
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

import ProtonCore_Networking
import ProtonCore_Services

public final class AuthDelegateMock: AuthDelegate {
    
    public init() {}

    @FuncStub(AuthDelegateMock.getToken, initialReturn: nil) public var getTokenStub
    public func getToken(bySessionUID uid: String) -> AuthCredential? { getTokenStub(uid) }
    
    @FuncStub(AuthDelegateMock.onLogout) public var onLogoutStub
    public func onLogout(sessionUID uid: String) { onLogoutStub(uid) }
    
    @FuncStub(AuthDelegateMock.onUpdate) public var onUpdateStub
    public func onUpdate(auth: Credential) { onUpdateStub(auth) }
    
    @FuncStub(AuthDelegateMock.onRefresh) public var onRefreshStub
    public func onRefresh(bySessionUID uid: String, complete: @escaping AuthRefreshComplete) {
        onRefreshStub(uid, complete)
    }
}
