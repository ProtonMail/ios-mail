//
//  AccountDeletionRobot.swift
//  ProtonCore-TestingToolkit - Created on 03.06.2021.
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

import XCTest
import pmtest
import ProtonCore_CoreTranslation

private let accountDeletionButtonText = CoreString._ad_delete_account_button

public final class AccountDeletionButtonRobot: CoreElements {
    
    public enum Kind {
        case button
        case staticText
    }

    public let verify = Verify()
    
    private func elementOfKind(_ type: Kind) -> UiElement {
        switch type {
        case .button: return button(accountDeletionButtonText)
        case .staticText: return staticText(accountDeletionButtonText)
        }
    }

    public func openAccountDeletionWebView<T: CoreElements>(type: Kind, to robot: T.Type) -> T {
        elementOfKind(type).wait(time: 20.0).tap()
        return T()
    }
    
    public func performAccountDeletion<T: CoreElements>(password: String, to: T.Type) -> T {
        self
            .verify.accountDeletionButtonIsDisplayed(type: .button)
            .openAccountDeletionWebView(type: .button, to: AccountDeletionWebViewRobot.self)
            .verify.accountDeletionWebViewIsOpened()
            .verify.accountDeletionWebViewIsLoaded()
            .goThroughAccountDeletionForm(password: password, to: T.self)
    }

    public final class Verify: CoreElements {
        @discardableResult
        public func accountDeletionButtonIsDisplayed(type: Kind) -> AccountDeletionButtonRobot {
            let robot = AccountDeletionButtonRobot()
            robot.elementOfKind(type).wait(time: 20.0).checkExists()
            return robot
        }
        
        @discardableResult
        public func accountDeletionButtonIsNotShown(type: Kind) -> AccountDeletionButtonRobot {
            let robot = AccountDeletionButtonRobot()
            robot.elementOfKind(type).wait().checkDoesNotExist()
            return robot
        }
    }
}

private let accountDeletionWebViewIndentifier = "AccountDeletionWebView.webView"
private let accountDeletionLeftBarButtonItemIdentifier = "AccountDeletionWebViewController.leftBarButtonItem"
private let accountDeletionWebpageLoadedStaticTextIdentifier = "What is the main reason you are deleting your account?"
private let accountDeletionSelectReasonIdentifier = "Select a reason"
private let accountDeletionReasonNotListedIdentifier = "My reason isn't listed"
private let accountDeletionFeedbackIdentifier = "Feedback"
private let accountDeletionEmailIdentifier = "Email address"
private let accountDeletionPasswordIdentifier = "Password"
private let accountDeletionConfirmationIdentifier = "Yes, I want to permanently delete this account and all its data."
private let accountDeletionDeleteIdentifier = "Delete"
private let accountDeletionCancelIdentifier = "Cancel"
private let keyboardDoneButtonIdentifier = "Done"

public final class AccountDeletionWebViewRobot: CoreElements {
    
    private static let defaultTimeout: TimeInterval = 30.0

    public let verify = Verify()

    public final class Verify: CoreElements {
        @discardableResult
        public func accountDeletionWebViewIsOpened() -> AccountDeletionWebViewRobot {
            webView(accountDeletionWebViewIndentifier).wait(time: AccountDeletionWebViewRobot.defaultTimeout).checkExists()
            return AccountDeletionWebViewRobot()
        }
        
        @discardableResult
        public func accountDeletionWebViewIsLoaded(application: XCUIApplication = .init()) -> AccountDeletionWebViewRobot {
            guard application
                    .webViews[accountDeletionWebViewIndentifier]
                    .staticTexts[accountDeletionWebpageLoadedStaticTextIdentifier]
                    .waitForExistence(timeout: AccountDeletionWebViewRobot.defaultTimeout) else {
                XCTFail()
                return AccountDeletionWebViewRobot()
            }
            return AccountDeletionWebViewRobot()
        }
    }
    
    public func setDeletionReason(application: XCUIApplication = .init()) -> AccountDeletionWebViewRobot {
        let deletionList = application.webViews[accountDeletionWebViewIndentifier].buttons[accountDeletionSelectReasonIdentifier]
        guard deletionList.waitForExistence(timeout: AccountDeletionWebViewRobot.defaultTimeout) else { XCTFail(); return AccountDeletionWebViewRobot() }
        deletionList.tap()
        let reasonCell = application.webViews[accountDeletionWebViewIndentifier].buttons[accountDeletionReasonNotListedIdentifier]
        guard reasonCell.waitForExistence(timeout: 1) else { XCTFail(); return AccountDeletionWebViewRobot() }
        reasonCell.tap()
        return AccountDeletionWebViewRobot()
    }
    
    public func fillInDeletionExplaination(text: String = "Testing deletion within the UI tests",
                                           application: XCUIApplication = .init()) -> AccountDeletionWebViewRobot {
        let element = application.webViews[accountDeletionWebViewIndentifier].textViews[accountDeletionFeedbackIdentifier]
        guard element.waitForExistence(timeout: AccountDeletionWebViewRobot.defaultTimeout) else { XCTFail(); return AccountDeletionWebViewRobot() }
        element.tap()
        element.typeText(text)
        closeKeyboard(application)
        return AccountDeletionWebViewRobot()
    }
    
    public func fillInDeletionEmail(text: String = "uitests@example.com",
                                    application: XCUIApplication = .init()) -> AccountDeletionWebViewRobot {
        let element = application.webViews[accountDeletionWebViewIndentifier].textFields[accountDeletionEmailIdentifier]
        guard element.waitForExistence(timeout: AccountDeletionWebViewRobot.defaultTimeout) else { XCTFail(); return AccountDeletionWebViewRobot() }
        element.tap()
        element.typeText(text)
        closeKeyboard(application)
        return AccountDeletionWebViewRobot()
    }
    
    public func fillInDeletionPassword(_ password: String, application: XCUIApplication = .init()) -> AccountDeletionWebViewRobot {
        application.webViews[accountDeletionWebViewIndentifier].swipeUp()
        let element = application.webViews[accountDeletionWebViewIndentifier].secureTextFields[accountDeletionPasswordIdentifier]
        guard element.waitForExistence(timeout: AccountDeletionWebViewRobot.defaultTimeout) else { XCTFail(); return AccountDeletionWebViewRobot() }
        element.tap()
        element.typeText(password)
        closeKeyboard(application)
        return AccountDeletionWebViewRobot()
    }
    
    public func confirmBeingAwareAccountDeletionIsPermanent(application: XCUIApplication = .init()) -> AccountDeletionWebViewRobot {
        application.webViews[accountDeletionWebViewIndentifier].swipeUp()
        let element = application.webViews[accountDeletionWebViewIndentifier].staticTexts[accountDeletionConfirmationIdentifier]
        guard element.waitForExistence(timeout: AccountDeletionWebViewRobot.defaultTimeout) else { XCTFail(); return AccountDeletionWebViewRobot() }
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        return AccountDeletionWebViewRobot()
    }
    
    public func tapDeleteAccountButton<T: CoreElements>(to: T.Type, application: XCUIApplication = .init()) -> T {
        let element = application.webViews[accountDeletionWebViewIndentifier].buttons[accountDeletionDeleteIdentifier]
        guard element.waitForExistence(timeout: AccountDeletionWebViewRobot.defaultTimeout) else { XCTFail(); return T() }
        element.tap()
        return T()
    }
    
    public func tapCancelButton<T: CoreElements>(to: T.Type, application: XCUIApplication = .init()) -> T {
        let element = application.webViews[accountDeletionWebViewIndentifier].buttons[accountDeletionCancelIdentifier]
        guard element.waitForExistence(timeout: AccountDeletionWebViewRobot.defaultTimeout) else { XCTFail(); return T() }
        element.tap()
        return T()
    }
    
    public func tapBackButton<T: CoreElements>(to: T.Type, application: XCUIApplication = .init()) -> T {
        button(accountDeletionLeftBarButtonItemIdentifier).tap()
        return T()
    }
    
    private func closeKeyboard(_ application: XCUIApplication) {
        application.buttons[keyboardDoneButtonIdentifier].tap()
    }
    
    public func goThroughAccountDeletionForm<T: CoreElements>(password: String, to: T.Type) -> T {
        self
            .setDeletionReason()
            .fillInDeletionExplaination()
            .fillInDeletionEmail()
            .fillInDeletionPassword(password)
            .confirmBeingAwareAccountDeletionIsPermanent()
            .tapDeleteAccountButton(to: T.self)
    }
}
