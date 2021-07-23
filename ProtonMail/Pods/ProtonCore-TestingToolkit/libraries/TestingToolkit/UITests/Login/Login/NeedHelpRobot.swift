//
//  NeedHelpRobot.swift
//  ProtonCore-TestingToolkit - Created on 29.04.2021.
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

import pmtest
import XCTest

private let helpTitleLabel = "HelpViewController.titleLabel"
private let helpViewCloseButtonId = "HelpViewController.closeButton"
private let forgotUsernameLabel = "Forgot username"
private let forgotPasswordLabel = "Forgot password"
private let otherSignInIssuesLabel = "Other sign-in issues"
private let customerSupportLabel = "Customer support"
private let forgotUsernamePageHeader = "Forgot Your Username?"
private let forgotPasswordPageHeader = "Reset Password"
private let commonLoginIssuesPageHeader = "Common Login Problems"
private let customerSupportPageHeader = "Support Form"

public final class NeedHelpRobot: CoreElements {
    
    public let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
    
    public func needHelpOptionsDisplayed() -> NeedHelpRobot {
        button(helpViewCloseButtonId).checkExists()
        staticText(forgotUsernameLabel).checkExists()
        staticText(forgotPasswordLabel).checkExists()
        staticText(otherSignInIssuesLabel).checkExists()
        staticText(customerSupportLabel).checkExists()
        return self
    }
    
    public func forgotUsernameLink() -> NeedHelpRobot {
        staticText(forgotUsernameLabel).tap()
        safari.staticTexts[forgotUsernamePageHeader].exists
        return NeedHelpRobot()
    }
    
    public func forgotPasswordLink() -> NeedHelpRobot {
        staticText(forgotPasswordLabel).tap()
        safari.staticTexts[forgotPasswordPageHeader].exists
        return NeedHelpRobot()
    }
    
    public func otherSignInIssuesLink() -> NeedHelpRobot {
        staticText(otherSignInIssuesLabel).tap()
        safari.staticTexts[commonLoginIssuesPageHeader].exists
        return NeedHelpRobot()
    }
    
    public func customerSupportLink() {
        staticText(customerSupportLabel).tap()
        safari.staticTexts[customerSupportPageHeader].exists
    }
    
    public func goBackToSampleApp() -> NeedHelpRobot {
        XCUIApplication().activate()
        return self
    }
    
    public func closeNeedHelpScreen() -> LoginRobot{
        button(helpViewCloseButtonId).wait().tap()
        return LoginRobot()
    }
}
