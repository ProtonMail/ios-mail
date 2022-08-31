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
import XCTest

class BackendConfigurationTests: XCTestCase {
    private let emptyLaunchArgs = [String]()
    private let uiTestsLaunchArgs = ["-uiTests"]

    private let emptyEnvVars = [String: String]()
    private var apiCustomAPIEnvVars: [String: String]!

    private let customAppDomain = "app.com"
    private let customApiDomain = "api.com"
    private let customApiPath = "/custom_api"

    override func setUp() {
        super.setUp()
        apiCustomAPIEnvVars = [
            "MAIL_APP_APP_DOMAIN": customAppDomain,
            "MAIL_APP_API_DOMAIN": customApiDomain,
            "MAIL_APP_API_PATH": customApiPath
        ]
    }

    func testSingleton_returnsProdEnv() {
        assertIsProduction(configuration: BackendConfiguration.shared)
    }

    func testInit_whenThereAreNoArgumentsOrVariables_returnsProdEnv() {
        let result = BackendConfiguration(launchArguments: emptyLaunchArgs, environmentVariables: emptyEnvVars)
        assertIsProduction(configuration: result)
    }

    func testInit_whenThereIsUITestsArg_andEnvVarsExist_returnsCustomEnv() {
        let result = BackendConfiguration(launchArguments: uiTestsLaunchArgs, environmentVariables: apiCustomAPIEnvVars)
        XCTAssert(result.environment.appDomain == customAppDomain)
        XCTAssert(result.environment.apiDomain == customApiDomain)
        XCTAssert(result.environment.apiPath == customApiPath)
    }

    func testInit_whenThereIsUITestsArg_andOneEnvVarIsMissing_returnsProdEnv() {
        var missingEnvVar: [String: String] = apiCustomAPIEnvVars
        missingEnvVar[missingEnvVar.keys.randomElement()!] = nil

        let result = BackendConfiguration(launchArguments: uiTestsLaunchArgs, environmentVariables: missingEnvVar)
        assertIsProduction(configuration: result)
    }

    private func assertIsProduction(
        configuration: BackendConfiguration,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(configuration.environment.appDomain, "proton.me", file: file, line: line)
        XCTAssertEqual(configuration.environment.apiDomain, "api.protonmail.ch", file: file, line: line)
        XCTAssertEqual(configuration.environment.apiPath, "", file: file, line: line)
    }
}
