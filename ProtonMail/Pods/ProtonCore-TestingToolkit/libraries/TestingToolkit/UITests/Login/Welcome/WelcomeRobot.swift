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

#if canImport(fusion)

import Foundation
import fusion
import ProtonCoreLoginUI

private let footerText = LUITranslation._ls_welcome_footer.l10n
private let logInButton = LUITranslation.sign_in_button.l10n
private let signUpButton = LUITranslation.create_account_button.l10n

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
        public func welcomeScreenIsShown(timeout: TimeInterval = 10.0) -> WelcomeRobot {
            staticText(footerText).wait(time: timeout).checkExists()
            return WelcomeRobot()
        }

        @discardableResult
        public func welcomeScreenIsNotPresented() -> WelcomeRobot {
            staticText(footerText).waitUntilGone()
            return WelcomeRobot()
        }

        @discardableResult
        public func welcomeScreenVariantIsShown(variant: WelcomeScreenVariant) -> WelcomeRobot {
            image(variant.imageNameForVariant).waitUntilExists().checkExists()
            return WelcomeRobot()
        }
        
        @discardableResult
        public func welcomeScreenVariantIsNotShown(variant: WelcomeScreenVariant) -> WelcomeRobot {
            image(variant.imageNameForVariant).waitUntilGone()
            return WelcomeRobot()
        }

        @discardableResult
        public func signUpButtonExists() -> WelcomeRobot {
            button(signUpButton).waitUntilExists().checkExists()
            return WelcomeRobot()
        }
        
        @discardableResult
        public func loginButtonExists() -> WelcomeRobot {
            button(logInButton).waitUntilExists().checkExists()
            return WelcomeRobot()
        }

        @discardableResult
        public func signUpButtonDoesNotExist() -> WelcomeRobot {
            button(signUpButton).waitUntilGone()
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

#endif
