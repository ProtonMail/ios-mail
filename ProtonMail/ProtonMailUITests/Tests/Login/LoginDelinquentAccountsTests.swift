//
//  LoginDelinquentAccountsTests.swift
//  Proton Mail - Created on 6/10/22.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import XCTest
import fusion
import RegexBuilder
import ProtonCoreQuarkCommands
import ProtonCoreTestingToolkitUITestsLogin

final class LoginDelinquentAccountsTests: FixtureAuthenticatedTestCase {

    let loginRobot = LoginRobot()
    private var username: String!
    private var password: String!
    
    override func setUpWithError() throws {
        super.setUp()
        username = StringUtils().randomAlphanumericString(length: 8)
        password = StringUtils().randomAlphanumericString(length: 8)
        user = User(name: username, password: password)

        try quarkCommands.newSeedNewSubscriber(user: user, plan: .mail2022, cycle: 12)
        try quarkCommands.updateDelinquentState(state: .overdueMoreThan14Days, for: username)
    }
    
    override func tearDown() {
        username = nil
        password = nil
    }

    func testLoginDelinquentAccount_shouldShowSignInViewAfterClickingOKButton() {
        loginRobot
            .fillUsername(username: user.name)
            .fillpassword(password: user.password)
            .signIn(robot: LoginRobot.self)
            .verify.delinquentError()
            .verify.loginScreenIsShown()
    }
}

extension LoginRobot.Verify {
    @discardableResult
    public func delinquentError() -> LoginRobot {
        let message = "Access to this account is disabled due to non-payment. Please sign in through proton.me to pay your unpaid invoice."
        LoginRobot().alert(message).waitUntilExists().checkExists()
        LoginRobot().button("OK").tap()
        return LoginRobot()
    }
}
