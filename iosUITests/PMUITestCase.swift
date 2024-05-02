// Copyright (c) 2024 Proton Technologies AG
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

import Foundation
import NIO
import XCTest

@MainActor
public class PMUITestCase: XCTestCase {
    var environment: UITestsEnvironment!
    var navigator: UITestNavigator!

    var loginType: UITestLoginType {
        UITestLoginType.Mocked.Paid.FancyCapybara
    }

    public override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override public func setUp() async throws {
        environment = UITestsEnvironment(
            mockServer: MockServer(bundle: Bundle(for: type(of: self)))
        )
        navigator = UITestNavigator(environment: environment, loginType: loginType)

        switch loginType {
        case .loggedIn(let user):
            await environment.mockServer.setupUserAuthorisationMocks(user: user)
        case .loggedOut:
            break
        }
    }

    override public func tearDown() {
        environment.mockServer.stop()
        super.tearDown()
    }
}
