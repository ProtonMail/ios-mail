//
//  RecoveryRobot.swift
//  ProtonCore-TestingToolkit - Created on 18.04.2021.
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

import Foundation
import XCTest
import pmtest
import ProtonCore_CoreTranslation

private let titleId = "RecoveryViewController.recoveryMethodTitleLabel"
private let emailTextFieldId = "RecoveryViewController.recoveryEmailTextField.textField"
private let phoneTextFieldId = "RecoveryViewController.recoveryPhoneTextField.textField"
private let phoneButtonId = "RecoveryViewController.recoveryPhoneTextField.pickerButton"
private let phonePickerId = "RecoveryViewController.recoveryPhoneTextField.pickerLabel"
private let skipButtonId = "UINavigationItem.rightBarButtonItem"
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
            button(phoneButtonId).checkHasLabel(code)
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
        public func skipButtonTap<T: CoreElements>(robot _: T.Type) -> T {
            button(recoveryDialogSkipButtonAccessibilityId).tap()
            return T()
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
