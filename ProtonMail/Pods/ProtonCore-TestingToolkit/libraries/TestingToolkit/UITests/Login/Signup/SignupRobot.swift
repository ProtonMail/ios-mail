//
//  SignupRobot.swift
//  ProtonCore-TestingToolkit - Created on 15.04.2021.
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
