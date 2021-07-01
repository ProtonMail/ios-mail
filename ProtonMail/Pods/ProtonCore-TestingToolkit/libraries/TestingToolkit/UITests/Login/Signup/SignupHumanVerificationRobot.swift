//
//  HumanVerificationRobot.swift
//  SampleAppUITests
//
//  Created by Greg on 19.04.21.
//

import Foundation
import XCTest
import pmtest
import ProtonCore_CoreTranslation

private let titleName = CoreString._hv_title
private let recaptchaButtonCheckName = "Recaptcha requires verification. I'm not a robot"
private let closeButtonAccessibilityId = "closeButton"

public final class SignupHumanVerificationRobot: CoreElements {
    
    public let verify = Verify()
    
    public final class Verify: CoreElements {
        @discardableResult
        public func humanVerificationScreenIsShown() -> SignupHumanVerificationRobot {
            staticText(titleName).wait().checkExists()
            return SignupHumanVerificationRobot()
        }
        
        public func isHumanVerificationRequired() -> SignupHumanVerificationRobot? {
            let staticText = XCUIApplication().staticTexts[titleName]
            Wait().forElement(staticText)
            return staticText.exists ? SignupHumanVerificationRobot() : nil
        }
    }

    public func humanVericicationCaptchaTap<Robot: CoreElements>(to: Robot.Type) -> Robot {
        let element = XCUIApplication().webViews.webViews.switches[recaptchaButtonCheckName]
        Wait().forElement(element)
        element.tap()
        return Robot()
    }
    
    public func closeButton() -> RecoveryRobot {
        button(closeButtonAccessibilityId).tap()
        return RecoveryRobot()
    }
}

