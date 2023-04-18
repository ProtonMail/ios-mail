// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

@testable import ProtonMail
import ProtonCore_Environment
import XCTest

class BackendConfigurationTests: XCTestCase {
    private static let customApiDomain = "example.com"

    private var sut: BackendConfiguration!
    private var mockBackendConfigurationCache: MockBackendConfigurationCacheProtocol!
    private let emptyLaunchArgs = [String]()
    private let uiTestsLaunchArgs = ["-uiTests"]

    private let emptyEnvVars = [String: String]()
    private var apiCustomAPIEnvVars = ["MAIL_APP_API_DOMAIN": BackendConfigurationTests.customApiDomain]

    override func setUp() {
        super.setUp()
        mockBackendConfigurationCache = MockBackendConfigurationCacheProtocol()
    }

    override func tearDown() {
        super.tearDown()
        mockBackendConfigurationCache = nil
        sut = nil
    }

    func testInit_whenThereIsUITestsArg_andEnvVarsExist_returnsCustomEnv() {
        sut = BackendConfiguration(launchArguments: uiTestsLaunchArgs, environmentVariables: apiCustomAPIEnvVars)
        XCTAssert(sut.environment == .custom(BackendConfigurationTests.customApiDomain))
    }

    func testInit_whenIsDebugOrEnterprise_returnsCachedEnv() {
        mockBackendConfigurationCache.readEnvironmentStub.bodyIs({ _ in
            Environment.black
        })
        sut = BackendConfiguration(isDebugOrEnterprise: { true }, configurationCache: mockBackendConfigurationCache)
        XCTAssert(sut.environment == .black)
    }

    func testInit_whenIsDebugOrEnterprise_andCacheReturnsNil_returnsProdEnv() {
        mockBackendConfigurationCache.readEnvironmentStub.bodyIs({ _ in
            nil
        })
        sut = BackendConfiguration(isDebugOrEnterprise: { true }, configurationCache: mockBackendConfigurationCache)
        XCTAssert(sut.environment == .mailProd)
    }

    func testInit_whenIsNotDebugOrEnterprise_returnsProdEnv() {
        mockBackendConfigurationCache.readEnvironmentStub.bodyIs({ _ in
            Environment.black
        })
        sut = BackendConfiguration(isDebugOrEnterprise: { false }, configurationCache: mockBackendConfigurationCache)
        XCTAssert(sut.environment == .mailProd)
    }

    func testIsProduction_whenItIsProduction_returnsTrue() {
        sut = BackendConfiguration(
            isDebugOrEnterprise: { false }
        )
        XCTAssertTrue(sut.isProduction)
    }

    func testIsProduction_whenItIsNotProduction_returnsFalse() {
        mockBackendConfigurationCache.readEnvironmentStub.bodyIs({ _ in
            Environment.black
        })
        sut = BackendConfiguration(isDebugOrEnterprise: { true }, configurationCache: mockBackendConfigurationCache)
        XCTAssertFalse(sut.isProduction)
    }

    func testEnvironment_whenItIsProduction_returnsTheExpectedDomains() {
        sut = BackendConfiguration(isDebugOrEnterprise: { false })
        assertIsProduction(configuration: sut)
    }
}

extension BackendConfigurationTests {

    private func assertIsProduction(
        configuration: BackendConfiguration,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(configuration.environment.doh.signupDomain, "proton.me", file: file, line: line)
        XCTAssertEqual(configuration.environment.doh.defaultHost, "https://mail-api.proton.me", file: file, line: line)
        XCTAssertEqual(configuration.environment.doh.defaultPath, "", file: file, line: line)
    }
}
