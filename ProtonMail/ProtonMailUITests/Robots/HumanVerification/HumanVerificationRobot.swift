//
//  HumanVerificationRobot.swift
//  ProtonMailUITests
//
//  Created by Greg on 16.04.21.
//  Copyright © 2021 ProtonMail. All rights reserved.
//

import XCTest
import PMCoreTranslation

private let title = CoreString._hv_title
private let emailButton = CoreString._hv_email_method_name
private let smsButton = CoreString._hv_sms_method_name
private let captchaButton = CoreString._hv_captha_method_name
private let recaptchaButtonCheck = "Recaptcha requires verification. I'm not a robot"

class HumanVerificationRobot {
    
    let verify = Verify()
    
    class Verify {
        @discardableResult
        func humanVerificationScreenIsShown() -> HumanVerificationRobot {
            Element.wait.forStaticTextFieldWithIdentifier(title)
            return HumanVerificationRobot()
        }
    }
    
    func emailTab() -> HumanVerificationRobot {
        Element.wait.forButtonWithIdentifier(emailButton).tap()
        return HumanVerificationRobot()
    }
    
    func smsTab() -> HumanVerificationRobot {
        Element.wait.forButtonWithIdentifier(smsButton).tap()
        return HumanVerificationRobot()
    }
    
    func captchaTab() -> HumanVerificationRobot {
        Element.wait.forButtonWithIdentifier(captchaButton).tap()
        return HumanVerificationRobot()
    }
    
    @discardableResult
    func captchaTap() -> HumanVerificationRobot {
        let element = XCUIApplication().webViews.webViews.switches[recaptchaButtonCheck]
        Wait().forElement(element, #file, #line, 10)
        element.tap()
        return HumanVerificationRobot()
    }
    
    @discardableResult
    func close() -> MenuRobot {
        let element = XCUIApplication().navigationBars[title].children(matching: .button).element(boundBy: 0)
        Wait().forElement(element, #file, #line, 10)
        element.tap()
        return MenuRobot()
    }
    
}
