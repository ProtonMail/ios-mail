//
//  SignupRobot.swift
//  SampleAppUITests
//
//  Created by Greg on 15.04.21.
//

import Foundation
import pmtest
import ProtonCore_CoreTranslation

private let titleId = "SignupViewController.createAccountTitleLabel"
private let nameTextFieldId = "SignupViewController.nameTextField.textField"
private let nextButtonId = "SignupViewController.nextButton"
private let signinButtonId = "SignupViewController.signinButton"
private let errorBannerMessage = "Username already used"
private let errorBannerButton = CoreString._hv_ok_button
private let otherAccountButton = "SignupViewController.otherAccountButton"
private let otherAccountExtName = CoreString._su_email_address_button
private let otherAccountIntName = CoreString._su_proton_address_button
private let closeButton = "UINavigationItem.leftBarButtonItem"

public final class SignupRobot: CoreElements {
    
    public let verify = Verify()
    
    public final class Verify: CoreElements {

        @discardableResult
        public func signupScreenIsShown() -> SignupRobot {
            staticText(titleId).wait().checkExists()
            return SignupRobot()
        }
        
        @discardableResult
        public func usernameAlreadyExists() -> SignupRobot {
            textView(errorBannerMessage).wait().checkExists()
            button(errorBannerButton).wait().checkExists().tap()
            return SignupRobot()
        }
        
        @discardableResult
        public func closeButtonIsShown() -> SignupRobot {
            button(closeButton).wait().checkExists()
            return SignupRobot()
        }
        
        @discardableResult
        public func closeButtonIsNotShown() -> SignupRobot {
            button(closeButton).checkDoesNotExist()
            return SignupRobot()
        }
        
        @discardableResult
        public func otherAccountIntButtonIsShown() -> SignupRobot {
            button(otherAccountIntName).wait().checkExists()
            return SignupRobot()
        }

        @discardableResult
        public func otherAccountExtButtonIsShown() -> SignupRobot {
            button(otherAccountExtName).wait().checkExists()
            return SignupRobot()
        }

        @discardableResult
        public func otherAccountButtonIsNotShown() -> SignupRobot {
            button(otherAccountButton).checkDoesNotExist()
            return SignupRobot()
        }
    }
    
    public func insertName(name: String) -> SignupRobot {
        textField(nameTextFieldId).tap().typeText(name)
        return self
    }
    
    public func nextButtonTap<T: CoreElements>(robot _: T.Type) -> T {
        button(nextButtonId).tap()
        return T()
    }
    
    public func signinButtonTap() -> LoginRobot {
        button(signinButtonId).tap()
        return LoginRobot()
    }

    public func otherAccountButtonTap() -> SignupRobot {
        button(otherAccountButton).tap()
        return self
    }

}
