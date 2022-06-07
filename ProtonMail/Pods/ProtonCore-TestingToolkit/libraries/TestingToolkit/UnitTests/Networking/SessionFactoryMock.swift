//
//  SessionFactoryMock.swift
//  ProtonCore-TestingToolkit - Created on 16.02.2022.
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

public final class SessionFactoryMock: SessionFactoryInterface {
    
    public init() {}
    
    @FuncStub(SessionFactoryMock.createSessionInstance, initialReturn: .crash) public var createSessionInstanceStub
    public func createSessionInstance(url apiHostUrl: String) -> Session { createSessionInstanceStub(apiHostUrl) }
    
    @FuncStub(SessionFactoryMock.createSessionRequest, initialReturn: .crash) public var createSessionRequestStub
    public func createSessionRequest(parameters: Any?, urlString: String, method: HTTPMethod, timeout: TimeInterval) -> SessionRequest {
        createSessionRequestStub(parameters, urlString, method, timeout)
    }
}
