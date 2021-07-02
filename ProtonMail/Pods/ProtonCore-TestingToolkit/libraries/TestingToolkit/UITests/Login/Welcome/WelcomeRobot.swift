//
//  LoginRobot.swift
//  SampleAppUITests
//
//  Created by denys zelenchuk on 11.02.21.
//
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
            case .mail: return "WelcomeMailLogo"
            case .calendar: return "WelcomeCalendarLogo"
            case .drive: return "WelcomeDriveLogo"
            case .vpn: return "WelcomeVPNLogo"
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
