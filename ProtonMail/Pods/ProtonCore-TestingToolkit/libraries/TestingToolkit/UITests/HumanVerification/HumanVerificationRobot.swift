//
//  HumanVerificationRobot.swift
//  ProtonMailUITests
//
//  Created by Greg on 16.04.21.
//  Copyright © 2021 ProtonMail. All rights reserved.
//

import XCTest
import ProtonCore_CoreTranslation
import pmtest

private let title = CoreString._hv_title
private let emailButton = CoreString._hv_email_method_name
private let smsButton = CoreString._hv_sms_method_name
private let captchaButton = CoreString._hv_captha_method_name
private let recaptchaButtonCheck = "Recaptcha requires verification. I'm not a robot"

public final class HumanVerificationRobot: CoreElements {
    
    public let verify = Verify()
    
    public final class Verify: CoreElements {
        @discardableResult
        public func humanVerificationScreenIsShown() -> HumanVerificationRobot {
            staticText(title).wait().checkExists()
            return HumanVerificationRobot()
        }
    }
    
    public func emailTab() -> HumanVerificationRobot {
        button(emailButton).wait().tap()
        return HumanVerificationRobot()
    }
    
    public func smsTab() -> HumanVerificationRobot {
        button(smsButton).wait().tap()
        return HumanVerificationRobot()
    }
    
    public func captchaTab() -> HumanVerificationRobot {
        button(captchaButton).wait().tap()
        return HumanVerificationRobot()
    }
    
    @discardableResult
    public func captchaTap() -> HumanVerificationRobot {
        let element = XCUIApplication().webViews.webViews.switches[recaptchaButtonCheck]
        Wait().forElement(element, #file, #line) // #, 10) <- this timeout option is not on PMTestAutomation
        element.tap()
        return HumanVerificationRobot()
    }
    
    @discardableResult
    public func close<Robot: CoreElements>(to _: Robot.Type) -> Robot {
        let element = XCUIApplication().navigationBars[title].children(matching: .button).element(boundBy: 0)
        Wait().forElement(element, #file, #line) // #, 10) <- this timeout option is not on PMTestAutomation
        element.tap()
        return Robot()
    }
    
}
