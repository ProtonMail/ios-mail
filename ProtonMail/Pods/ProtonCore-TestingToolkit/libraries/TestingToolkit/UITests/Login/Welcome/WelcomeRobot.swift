//
//  LoginRobot.swift
//  ProtonCore-TestingToolkit - Created on 11.02.2021.
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

import pmtest
import ProtonCore_CoreTranslation

private let footerText = CoreString._ls_welcome_footer
private let logInButton = CoreString._ls_sign_in_button
private let signUpButton = CoreString._ls_create_account_button

public final class WelcomeRobot: CoreElements {

    public enum WelcomeScreenVariant {
        case mail
        case calendar
        case vpn
        case drive

        var imageNameForVariant: String {
            switch self {
            case .mail: return "MailMain"
            case .calendar: return "CalendarMain"
            case .drive: return "DriveMain"
            case .vpn: return "VPNMain"
            }
        }
    }

    public let verify = Verify()

    public final class Verify: CoreElements {

        @discardableResult
        public func welcomeScreenIsShown() -> WelcomeRobot {
            staticText(footerText).wait().checkExists()
            return WelcomeRobot()
        }

        @discardableResult
        public func welcomeScreenIsNotPresented() -> WelcomeRobot {
            staticText(footerText).wait().checkDoesNotExist()
            return WelcomeRobot()
        }

        @discardableResult
        public func welcomeScreenVariantIsShown(variant: WelcomeScreenVariant) -> WelcomeRobot {
            image(variant.imageNameForVariant).wait().checkExists()
            return WelcomeRobot()
        }

        @discardableResult
        public func signUpButtonExists() -> WelcomeRobot {
            button(signUpButton).wait().checkExists()
            return WelcomeRobot()
        }

        @discardableResult
        public func signUpButtonDoesNotExist() -> WelcomeRobot {
            button(signUpButton).wait().checkDoesNotExist()
            return WelcomeRobot()
        }
    }

    public func logIn() -> LoginRobot {
        button(logInButton).tap()
        return LoginRobot()
    }

    public func signUp() -> SignupRobot {
        button(signUpButton).tap()
        return SignupRobot()
    }
}
