//
//  HumanVerifyResponseDelegateMock.swift
//  ProtonCore-TestingToolkit - Created on 03.06.2021.
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

import ProtonCore_Services

public final class HumanVerifyResponseDelegateMock: HumanVerifyResponseDelegate {

    public init() {}

    @FuncStub(HumanVerifyResponseDelegateMock.onHumanVerifyStart) public var onHumanVerifyStartStub
    public func onHumanVerifyStart() {
        onHumanVerifyStartStub()
    }

    @FuncStub(HumanVerifyResponseDelegateMock.onHumanVerifyEnd) public var onHumanVerifyEndStub
    public func onHumanVerifyEnd(result: HumanVerifyEndResult) {
        onHumanVerifyEndStub(result)
    }
    
    @FuncStub(HumanVerifyResponseDelegateMock.humanVerifyToken) public var humanVerifyTokenStub
    public func humanVerifyToken(token: String?, tokenType: String?) {
        humanVerifyTokenStub(token, tokenType)
    }
}
