//
//  APIServiceLoggingDelegateMock.swift
//  ProtonCore-TestingToolkit - Created on 22.06.2023.
//
//  Copyright (c) 2023 Proton Technologies AG
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

import ProtonCoreServices
#if canImport(ProtonCoreTestingToolkitUnitTestsCore)
import ProtonCoreTestingToolkitUnitTestsCore
#endif

public final class APIServiceLoggingDelegateMock: APIServiceLoggingDelegate {
    
    public init() {}
    
    @FuncStub(APIServiceLoggingDelegateMock.accessTokenRefreshDidStart) public var accessTokenRefreshDidStartStub
    public func accessTokenRefreshDidStart(for sessionID: String,
                                           sessionType: APISessionTypeForLogging) {
        accessTokenRefreshDidStartStub(sessionID, sessionType)
    }
    
    @FuncStub(APIServiceLoggingDelegateMock.accessTokenRefreshDidSucceed) public var accessTokenRefreshDidSucceedStub
    public func accessTokenRefreshDidSucceed(for sessionID: String,
                                             sessionType: APISessionTypeForLogging,
                                             reason: APIServiceAccessTokenRefreshSuccessReasonForLogging) {
        accessTokenRefreshDidSucceedStub(sessionID, sessionType, reason)
    }
    
    @FuncStub(APIServiceLoggingDelegateMock.accessTokenRefreshDidFail) public var accessTokenRefreshDidFailStub
    public func accessTokenRefreshDidFail(for sessionID: String,
                                          sessionType: APISessionTypeForLogging,
                                          error: APIServiceAccessTokenRefreshErrorForLogging) {
        accessTokenRefreshDidFailStub(sessionID, sessionType, error)
    }
}
