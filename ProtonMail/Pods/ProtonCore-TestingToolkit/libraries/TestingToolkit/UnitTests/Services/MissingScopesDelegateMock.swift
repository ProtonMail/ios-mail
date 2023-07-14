//
//  MissingScopesDelegateMock.swift
//  ProtonCore-TestingToolkit - Created on 16.05.2023.
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
#if canImport(ProtonCore_TestingToolkit_UnitTests_Core)
import ProtonCore_TestingToolkit_UnitTests_Core
#endif
import ProtonCore_Networking
import ProtonCore_Services

public final class MissingScopesDelegateMock: MissingScopesDelegate {
    public init() {}
    
    @FuncStub(MissingScopesDelegateMock.onMissingScopesHandling) public var onMissingScopesHandlingStub
    public func onMissingScopesHandling(username: String, responseHandlerData: PMResponseHandlerData, completion: @escaping (MissingScopesFinishReason) -> Void) {
        onMissingScopesHandlingStub(username, responseHandlerData, completion)
    }
    
    @FuncStub(MissingScopesDelegateMock.showAlert) public var showAlert
    public func showAlert(title: String, message: String?) {
        showAlert(title, message)
    }
}