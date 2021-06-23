//
//  RecoveryRobot.swift
//  SampleAppUITests
//
//  Created by Greg on 18.04.21.
//

import Foundation
import XCTest
import pmtest
import ProtonCore_CoreTranslation

private let titleId = "RecoveryViewController.recoveryMethodTitleLabel"
private let emailTextFieldId = "RecoveryViewController.recoveryEmailTextField.textField"
private let phoneTextFieldId = "RecoveryViewController.recoveryPhoneTextField.textField"
private let phoneButtonId = "RecoveryViewController.recoveryPhoneTextField.pickerButton"
private let phonePickerId = "RecoveryViewController.recoveryPhoneTextField.pickerLabel"
private let skipButtonId = "RecoveryViewController.skipButton"
private let nextButtonId = "RecoveryViewController.nextButton"
private let segmenedControlId = "RecoveryViewController.methodSegmenedControl"
private let recoveryDialogTitleName = CoreString._su_recovery_skip_title
private let recoveryDialogMessageName = CoreString._su_recovery_skip_desc
private let recoveryDialogSkipButtonAccessibilityId = "DialogSkipButton"
private let recoveryDialogRecoveryButtonAccessibilityId = "DialogRecoveryMethodButton"
private let linkString = CoreString._su_recovery_t_c_link
private let errorBannerHVRequired = "Human verification required"
private let errorBannerInvalidNumber = "Phone number failed validation"
private let errorBannerButton = CoreString._hv_ok_button

public final class RecoveryRobot: CoreElements {
    
    public enum RecoveryMethod {
        case email
        case phone
        
        var getIndex: Int {
            switch self {
            case .email: return 0
            case .phone: return 1
            }
        }
    }
    
    public let verify = Verify()
    
    public final class Verify: CoreElements {
        @discardableResult
        public func recoveryScreenIsShown() -> RecoveryRobot {
            staticText(titleId).wait().checkExists()
            return RecoveryRobot()
        }

        @discardableResult
        public func nextButtonIsEnabled() -> RecoveryRobot {
            button(nextButtonId).waitForEnabled()
            return RecoveryRobot()
        }
        
        @discardableResult
        public func verifyCountryCode(code: String) -> RecoveryRobot {
            staticText(phonePickerId).checkHasLabel(code)
            return RecoveryRobot()
        }
        
        @discardableResult
        public func humanVerificationRequired() -> RecoveryRobot {
            textView(errorBannerHVRequired).wait().checkExists()
            button(errorBannerButton).tap()
            return RecoveryRobot()
        }

        @discardableResult
        public func phoneNumberInvalid() -> SignupRobot {
            textView(errorBannerInvalidNumber).wait().checkExists()
            button(errorBannerButton).wait().checkExists().tap()
            return SignupRobot()
        }
    }
    
    public func skipButtonTap() -> RecoveryDialogRobot {
        button(skipButtonId).tap()
        return RecoveryDialogRobot()
    }
    
    public func nextButtonTap() -> RecoveryRobot {
        button(nextButtonId).wait().tap()
        return self
    }
    
    public final class RecoveryDialogRobot: CoreElements {
        
        public let verify = Verify()
        
        public final class Verify: CoreElements {
            public func recoveryDialogDisplay() -> RecoveryDialogRobot {
                staticText(recoveryDialogTitleName).wait().checkExists()
                staticText(recoveryDialogMessageName).wait().checkExists()
                return RecoveryDialogRobot()
            }
        }

        @discardableResult
        public func skipButtonTap() -> CompleteRobot {
            button(recoveryDialogSkipButtonAccessibilityId).tap()
            return CompleteRobot()
        }
        
        @discardableResult
        public func recoveryMethodTap() -> RecoveryRobot {
            button(recoveryDialogRecoveryButtonAccessibilityId).tap()
            return RecoveryRobot()
        }
    }

    public func TCLinkTap() -> TCRobot {
        link(linkString).checkExists().tap()
        return TCRobot()
    }

    public func insertRecoveryEmail(email: String) -> RecoveryRobot {
        textField(emailTextFieldId).tap().typeText(email)
        return self
    }
    
    public func selectRecoveryMethod(method: RecoveryMethod) -> RecoveryRobot {
        segmentedControl(segmenedControlId).byIndex(0).tap()
        return self
    }
    
    public func insertRecoveryNumber(number: String) -> RecoveryRobot {
        textField(phoneTextFieldId).tap().typeText(number)
        return self
    }
    
    public func selectCountrySelector() -> CountrySelectorRobot {
        button(phoneButtonId).tap()
        return CountrySelectorRobot()
    }

}
