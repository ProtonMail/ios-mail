//
//  NeedHelpRobot.swift
//  SampleAppUITests
//
//  Created by Kristina Jureviciute on 2021-04-29.
//

import PMTestAutomation
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

