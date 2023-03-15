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

import ProtonCore_Environment
import ProtonCore_QuarkCommands
import ProtonCore_TestingToolkit

private enum CommonUnauthSessionTests {

    static let environment: Environment = .black

    static var endpoints: (String?, String?) {
        return (
            URL(string: environment.doh.defaultHost)?.host,
            environment.doh.defaultPath
        )
    }

    static func testBasicOperationsOnAccountAndMailWork(within testCase: XCTestCase) {
        let randomUsername = StringUtils().randomAlphanumericString(length: 8)
        let randomPassword = StringUtils().randomAlphanumericString(length: 8)

        let expectQuarkCommandToFinish = testCase.expectation(description: "Quark command should finish")
        var quarkCommandResult: Result<CreatedAccountDetails, CreateAccountError>?
        QuarkCommands.create(account: .freeWithAddressAndKeys(username: randomUsername, password: randomPassword),
                             currentlyUsedHostUrl: Environment.black.doh.getCurrentlyUsedHostUrl()) { result in
            quarkCommandResult = result
            expectQuarkCommandToFinish.fulfill()
        }

        testCase.wait(for: [expectQuarkCommandToFinish], timeout: 5.0)
        if case .failure(let error) = quarkCommandResult {
            XCTFail("Internal account creation failed in test \(#function) because of \(error.userFacingMessageInQuarkCommands)")
            return
        }
        
        let sentRobot = LoginRobot()
            .fillUsername(username: randomUsername)
            .fillpassword(password: randomPassword)
            .signIn(robot: InboxRobot.self)
            .compose()
            .editRecipients("\(randomUsername)@\(environment.doh.signupDomain)")
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

final class NoUnauthSessionTests: BaseTestCase {

    private var mailboxRobot: MailboxRobotInterface?

    override class func setUp() {
        super.setUp()
        (apiDomain, _) = CommonUnauthSessionTests.endpoints
    }

    override func setUp() {
        launchArguments.append("-testNoUnauthSessions")
        super.setUp()
    }

    func testRefreshingAndOpeningMailWorks() {
        CommonUnauthSessionTests.testBasicOperationsOnAccountAndMailWork(within: self)
    }

}

final class UnauthSessionTests: BaseTestCase {

    override class func setUp() {
        super.setUp()
        (apiDomain, _) = CommonUnauthSessionTests.endpoints
    }

    override func setUp() {
        launchArguments.append("-testUnauthSessionsWithHeader")
        super.setUp()
    }

    func testRefreshingAndOpeningMailWorks() {
        CommonUnauthSessionTests.testBasicOperationsOnAccountAndMailWork(within: self)
    }
}
