// Copyright (c) 2023 Proton Technologies AG
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

import XCTest

import ProtonCoreEnvironment
import ProtonCoreQuarkCommands

private enum CommonUnauthSessionTests {

    static func testBasicOperationsOnAccountAndMailWork(_ user: User) {
        MailboxRobotInterface()
            .compose()
            .editRecipients(user.email)
            .changeSubjectTo("unauth session tests")
            .send()
            .menuDrawer()
            .sent()
            .clickMessageByIndex(0)
            .moveToTrash()
            .menuDrawer()
            .logoutUser()
            .verify.loginScreenIsShown()
    }
}

final class NoUnauthSessionTests: FixtureAuthenticatedTestCase {

    override func setUp() {
        launchArguments.append("-testNoUnauthSessions")
        super.setUp()
    }

    // TODO: approach test author to understand why it is failing
    func xtestRefreshingAndOpeningMailWorks() {
        runTestWithScenario(.qaMail001) {
            CommonUnauthSessionTests.testBasicOperationsOnAccountAndMailWork(user)
        }
    }
}

final class UnauthSessionTests: FixtureAuthenticatedTestCase {

    override func setUp() {
        launchArguments.append("-testUnauthSessionsWithHeader")
        super.setUp()
    }
    
    func testRefreshingAndOpeningMailWorks() {
        runTestWithScenario(.qaMail001) {
            CommonUnauthSessionTests.testBasicOperationsOnAccountAndMailWork(user)
        }
    }
}
