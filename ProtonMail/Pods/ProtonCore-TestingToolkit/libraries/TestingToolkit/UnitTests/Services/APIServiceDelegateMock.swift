//
//  APIServiceDelegateMock.swift
//  ProtonCore-TestingToolkit - Created on 03.06.2021.
//
//  Copyright (c) 2021 Proton Technologies AG
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

import ProtonCore_Services

public final class APIServiceDelegateMock: APIServiceDelegate {
    
    public init() {}

    @PropertyStub(\APIServiceDelegateMock.locale, initialGet: "en_US") public var localeStub
    public var locale: String { localeStub() }
    
    @FuncStub(APIServiceDelegateMock.onUpdate) public var onUpdateStub
    public func onUpdate(serverTime: Int64) { onUpdateStub(serverTime) }

    @FuncStub(APIServiceDelegateMock.isReachable, initialReturn: false) public var isReachableStub
    public func isReachable() -> Bool { isReachableStub() }

    @PropertyStub(\APIServiceDelegateMock.appVersion, initialGet: .empty) public var appVersionStub
    public var appVersion: String { appVersionStub() }

    @PropertyStub(\APIServiceDelegateMock.userAgent, initialGet: nil) public var userAgentStub
    public var userAgent: String? { userAgentStub() }

    @FuncStub(APIServiceDelegateMock.onDohTroubleshot) public var onDohTroubleshotStub
    public func onDohTroubleshot() { onDohTroubleshotStub() }
}
