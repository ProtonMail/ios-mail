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
    private var apiCustomAPIEnvVars: [String: String]!

    private let customApiDomain = "example.com"

    override func setUp() {
        super.setUp()
        apiCustomAPIEnvVars = [
            "MAIL_APP_API_DOMAIN": customApiDomain
        ]
    }

    func testSingleton_returnsProdEnv() {
        assertIsProduction(configuration: BackendConfiguration.shared)
    }

    func testInit_whenNoCustomDomain_returnsProdEnv() {
        let result = BackendConfiguration(environmentVariables: [:])
        assertIsProduction(configuration: result)
    }

    func testInit_whenNecessaryEnvVarExist_returnsCustomEnv() {
        let result = BackendConfiguration(environmentVariables: apiCustomAPIEnvVars)
        switch result.environment {
        case .custom(customApiDomain):
            break
        default:
            XCTFail("Unexpected environment: \(result.environment)")
        }
    }

    private func assertIsProduction(
        configuration: BackendConfiguration,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        switch configuration.environment {
        case .mailProd:
            break
        default:
            XCTFail("Unexpected environment: \(configuration.environment)", file: file, line: line)
        }

        XCTAssert(configuration.isProduction, file: file, line: line)
    }
}
