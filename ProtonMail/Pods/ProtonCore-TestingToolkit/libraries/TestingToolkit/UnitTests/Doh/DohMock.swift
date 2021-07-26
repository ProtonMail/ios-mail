//
//  DohMock.swift
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

import XCTest
import ProtonCore_Doh

public struct DohInterfaceMock: DoHInterface, ServerConfig {

    public init() {}

    @PropertyStub(\DohInterfaceMock.apiHost, initialGet: .crash) public var apiHostStub
    public var apiHost: String { apiHostStub() }

    @PropertyStub(\DohInterfaceMock.blockList, initialGet: .crash) public var blockListStub
    public var blockList: [String: Int] { blockListStub() }

    @PropertyStub(\DohInterfaceMock.captchaHost, initialGet: .crash) public var captchaHostStub
    public var captchaHost: String { captchaHostStub() }

    @FuncStub(DohInterfaceMock.clearAll) public var clearAllStub
    public func clearAll() { clearAllStub() }

    @FuncStub(DohInterfaceMock.codeCheck, initialReturn: .crash) public var codeCheckStub
    public func codeCheck(code: Int) -> Bool { codeCheckStub(code) }

    @PropertyStub(\DohInterfaceMock.debugBlock, initialGet: .crash) public var debugBlockStub
    public var debugBlock: [String: Bool] { debugBlockStub() }

    @PropertyStub(\DohInterfaceMock.debugMode, initialGet: .crash) public var debugModeStub
    public var debugMode: Bool { debugModeStub() }

    @PropertyStub(\DohInterfaceMock.defaultHost, initialGet: .crash) public var defaultHostStub
    public var defaultHost: String { defaultHostStub() }

    @PropertyStub(\DohInterfaceMock.defaultPath, initialGet: .crash) public var defaultPathStub
    public var defaultPath: String { defaultPathStub() }

    @PropertyStub(\DohInterfaceMock.enableDoh, initialGet: .crash) public var enableDohStub
    public var enableDoh: Bool { enableDohStub() }

    @FuncStub(DohInterfaceMock.getCaptchaHostUrl, initialReturn: .crash) public var getCaptchaHostUrlStub
    public func getCaptchaHostUrl() -> String { getCaptchaHostUrlStub() }

    @FuncStub(DohInterfaceMock.getHostUrl, initialReturn: .crash) public var getHostUrlStub
    public func getHostUrl() -> String { getHostUrlStub() }

    @FuncStub(DohInterfaceMock.handleError, initialReturn: .crash) public var handleErrorStub
    public func handleError(host: String, error: Error?) -> Bool { handleErrorStub(host, error) }

    @PropertyStub(\DohInterfaceMock.signupDomain, initialGet: .crash) public var signupDomainStub
    public var signupDomain: String { signupDomainStub() }

    @PropertyStub(\DohInterfaceMock.status, initialGet: .crash) public var statusStub
    public var status: DoHStatus { statusStub() }

}

public final class DohMock: DoH, ServerConfig {

    override public init() throws {}

    @PropertyStub(\DohInterfaceMock.defaultHost, initialGet: Dummy.url) public var defaultHostStub
    public var defaultHost: String { defaultHostStub() }

    @PropertyStub(\DohInterfaceMock.captchaHost, initialGet: .crash) public var captchaHostStub
    public var captchaHost: String { captchaHostStub() }

    @PropertyStub(\DohInterfaceMock.apiHost, initialGet: Dummy.domain) public var apiHostStub
    public var apiHost: String { apiHostStub() }

    @PropertyStub(\DohInterfaceMock.defaultPath, initialGet: Dummy.apiPath) public var defaultPathStub
    public var defaultPath: String { defaultPathStub() }

    @PropertyStub(\DohInterfaceMock.signupDomain, initialGet: .crash) public var signupDomainStub
    public var signupDomain: String { signupDomainStub() }
}
