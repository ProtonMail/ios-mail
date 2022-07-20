// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import XCTest
import ProtonCore_Doh
import ProtonCore_TestingToolkit
import ProtonCore_QuarkCommands

final class DeleteAccountTests: BaseTestCase {
    
    var doh: (DoH & ServerConfig)? {
        guard let apiDomain = apiDomain else { return nil }
        guard let appDomain = appDomain else { return nil }
        guard let apiPath = apiPath else { return nil }
        return CustomServerConfigDoH(
            signupDomain: appDomain,
            captchaHost: "https://api.\(apiDomain)",
            humanVerificationV3Host: "https://verify.\(appDomain)",
            accountHost: "https://account.\(appDomain)",
            defaultHost: "https://\(apiDomain)",
            apiHost: "",
            defaultPath: apiPath
        )
    }
    
    private let robot = AccountDeletionButtonRobot()
    private let loginRobot = LoginRobot()
    
    override class func setUp() {
        environmentFileName = "environment_black"
        super.setUp()
    }
    
    override func setUp() {
        usesBlackCredentialsFile = false
        super.setUp()
    }
    
    func withUserCreated(callPerformOn: DispatchQueue = .main, perform: @escaping (User) -> Void) {
        let expectation = expectation(description: "should create a user \(UUID().uuidString)")
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            QuarkCommands.create(account: .paid(plan: "plus", username: nil, password: nil),
                                 currentlyUsedHostUrl: doh?.getCurrentlyUsedHostUrl() ?? "",
                                 callCompletionBlockOn: .global(qos: .userInitiated)) { result in
                switch result {
                case .success(let details):
                    let user = User(email: "\(details.account.username)@\(appDomain ?? "")",
                                    password: details.account.password,
                                    mailboxPassword: details.account.mailboxPassword ?? "",
                                    twoFASecurityKey: "")
                    callPerformOn.async {
                        perform(user)
                        expectation.fulfill()
                    }
                    
                case .failure(let error):
                    XCTFail("no user created means no way of testing its deletion :shrug: creation error: \(error)")
                    expectation.fulfill()
                }
            }
        }
        wait(for: [expectation], timeout: 600.0, enforceOrder: true)
    }
    
    @discardableResult
    func logIn(user: User) -> AccountSettingsRobot {
        loginRobot
            .loginUser(user)
            .menuDrawer()
            .settings()
            .selectAccount(user.email)
            .verify.deleteAccountShown()
    }

    func testDeleteAccountExists()  {
        withUserCreated { [self] user in
            
            logIn(user: user)
            
            robot
                .verify.accountDeletionButtonIsDisplayed(type: .staticText)
            
        }
    }
    
    func testDeleteAccountCanBeClosed() {
        withUserCreated { [self] user in
            
            logIn(user: user)
            
            robot
                .openAccountDeletionWebView(type: .staticText, to: AccountDeletionWebViewRobot.self)
                .verify.accountDeletionWebViewIsOpened()
                .verify.accountDeletionWebViewIsLoaded(application: app)
                .tapCancelButton(to: AccountDeletionButtonRobot.self)
                .verify.accountDeletionButtonIsDisplayed(type: .staticText)
        }
    }
    
    func testLoginScreenIsShownAfterSuccessfulDeletion() {
        withUserCreated { [self] user in
            
            logIn(user: user)
            
            robot
                .openAccountDeletionWebView(type: .staticText, to: AccountDeletionWebViewRobot.self)
                .verify.accountDeletionWebViewIsOpened()
                .verify.accountDeletionWebViewIsLoaded(application: app)
                .setDeletionReason()
                .fillInDeletionExplaination()
                .fillInDeletionEmail()
                .fillInDeletionPassword(user.password)
                .confirmBeingAwareAccountDeletionIsPermanent()
                .tapDeleteAccountButton(to: LoginRobot.self)
                .verify.loginScreenIsShown()
        }
    }
    
    func testSecondUserInboxIsShownAfterSuccessfulDeletionOfFirstUser() {
        withUserCreated(callPerformOn: .global(qos: .userInitiated)) { [self] user1 in
        withUserCreated { [self] user2 in
            
            logIn(user: user1)
                .navigateBackToSettings()
                .close()
                .menuDrawer()
                .accountsList()
                .manageAccounts()
                .addAccount()
                .connectOnePassAccount(user2)
                .menuDrawer()
                .settings()
                .selectAccount(user2.email)
                .verify.deleteAccountShown()
            
            robot
                .openAccountDeletionWebView(type: .staticText, to: AccountDeletionWebViewRobot.self)
                .verify.accountDeletionWebViewIsOpened()
                .verify.accountDeletionWebViewIsLoaded(application: app)
                .setDeletionReason()
                .fillInDeletionExplaination()
                .fillInDeletionEmail()
                .fillInDeletionPassword(user2.password)
                .confirmBeingAwareAccountDeletionIsPermanent()
                .tapDeleteAccountButton(to: InboxRobot.self)
                .verify.inboxShown()
                .menuDrawer()
                .verify.currentAccount(user1)
        }
        }
    }
}
