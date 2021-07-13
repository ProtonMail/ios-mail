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

    public enum HVOrCompletionRobot {
        case humanVerification(SignupHumanVerificationRobot)
        case complete(CompleteRobot)

        public func proceed<T: CoreElements>(to: T.Type) -> T {
            switch self {
            case .humanVerification(let hvRobot):
                return hvRobot
                    .verify.humanVerificationScreenIsShown()
                    .humanVericicationCaptchaTap(to: CompleteRobot.self)
                    .verify.completeScreenIsShown(robot: T.self)
            case .complete(let completeRobot):
                return completeRobot
                    .verify.completeScreenIsShown(robot: T.self)
            }
        }
    }
    
    public let verify = Verify()
    
    public final class Verify: CoreElements {
        @discardableResult
        public func humanVerificationScreenIsShown() -> SignupHumanVerificationRobot {
            staticText(titleName).wait().checkExists()
            return SignupHumanVerificationRobot()
        }
        
        public func isHumanVerificationRequired() -> HVOrCompletionRobot {
            let staticText = XCUIApplication().staticTexts[titleName]
            Wait(time: 5.0).forElement(staticText)
            return staticText.exists ? .humanVerification(SignupHumanVerificationRobot()) : .complete(CompleteRobot())
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

