//
//  PinRobot.swift
//  ProtonMailUITests
//
//  Created by mirage chung on 2020/12/17.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import XCTest
import fusion

fileprivate struct id {
    // App PIN page
    static let pinCellIdentifier = "SettingsLockView.pinCodeCell"
    static let nonePinCellIdentifier = "SettingsLockView.nonCell"
    static let changePinCellIdentifier = "SettingsLockView.changePingCodeCell"
    static let pinStaticTextLabel = LocalString._app_pin
    static let appKeySwitchIdentifier = "SettingsLockView.appKeySwitch"
    static let appKeyConfirmationAlertButtonLabel = "Continue"
    static let noneAutoLockButtonLabel = LocalString._general_none
    static let everyTimeLockButtonLabel = LocalString._settings_every_time_enter_app
    static let pinTimerCellIdentifier = "SettingsGeneralCell.Timing"
    static let backToSettingsNavBarButtonIdentifier = LocalString._menu_settings_title
    static let checkMarkButtonLabel = "checkmark"

    // PIN code setup page
    static let setPinStaticTextLabel =  L10n.PinCodeSetup.setPinCode
    static let repeatPinStaticTextLabel = L10n.PinCodeSetup.repeatPinCode
    static let changePinStaticTextLabel = L10n.PinCodeSetup.changePinCode
    static let disablePinStaticTextLabel = L10n.PinCodeSetup.disablePinCode
    static let pinTextFieldIdentifier = "PinCodeSetupView.passwordTextField.textField"
    static let confirmButtonIdentifier = "PinCodeSetupViewController.customView.confirmationButton"
    static let pinTextErrorLabelIdentifier = "PinCodeSetupView.passwordTextField.errorLabel"
}

class PinRobot: CoreElements {
    
    var verify = Verify()
    
    required init() {
        super.init()
    }
    
    func enablePin() -> setPinRobot {
        cell(id.pinCellIdentifier).tap()
        return setPinRobot()
    }

    func changePin() -> ChangePinRobot {
        cell(id.changePinCellIdentifier).tap()
        return ChangePinRobot()
    }
    
    func navigateUpToSettings() -> SettingsRobot {
        button(id.backToSettingsNavBarButtonIdentifier).tap()
        return SettingsRobot()
    }

    func openPinTimerSelection() -> AutoLockTimeRobot {
        cell(id.pinTimerCellIdentifier).tap()
        return AutoLockTimeRobot()
    }

    func enableAppKey() -> PinRobot {
        swittch(id.appKeySwitchIdentifier).tap()
        button(id.appKeyConfirmationAlertButtonLabel).tap()
        return PinRobot()
    }
    
    @discardableResult
    func disablePin() -> DisablePinRobot {
        cell(id.nonePinCellIdentifier).tap()
        return DisablePinRobot()
    }
    
    func backgroundApp() -> PinRobot {
        device().backgroundApp()
        return PinRobot()
    }
    
    func foregroundApp() -> PinInputRobot {
        device().foregroundApp(.launch)
        return PinInputRobot()
    }
    
    func activateAppWithPin() -> PinInputRobot {
        device().foregroundApp(.activate)
        return PinInputRobot()
    }
    
    func activateAppWithoutPin() -> PinRobot {
        device().foregroundApp(.activate)
        return PinRobot()
    }
    
    class AutoLockTimeRobot: CoreElements {
        
        func selectAutoLockNone() -> PinRobot {
            button(id.noneAutoLockButtonLabel).tap()
            return PinRobot()
        }
        
        func selectAutolockEveryTime() -> PinRobot {
            button(id.everyTimeLockButtonLabel).tap()
            return PinRobot()
        }
    }
    
    class setPinRobot: CoreElements {
        required init() {
            super.init()
            staticText(id.setPinStaticTextLabel).waitUntilExists().checkExists()
        }

        func enterPin(_ pin: String) -> setPinRobot {
            secureTextField(id.pinTextFieldIdentifier).tap().waitUntilExists().typeText(pin)
            return self
        }
        
        func continueSettingPin() -> RepeatPinRobot {
            button(id.confirmButtonIdentifier).tap()
            return RepeatPinRobot()
        }
        
        @discardableResult
        func setPin(_ pin: String) -> PinRobot {
            enterPin(pin)
                .continueSettingPin()
                .confirmPin(pin)
        }
    }
    
    class RepeatPinRobot: CoreElements {
        required init() {
            super.init()
            staticText(id.repeatPinStaticTextLabel).waitUntilExists().checkExists()
        }

        func enterPin(_ pin: String) -> RepeatPinRobot {
            secureTextField(id.pinTextFieldIdentifier).tap().typeText(pin)
            return self
        }
        
        func continueConfirm() -> PinRobot {
            button(id.confirmButtonIdentifier).tap()
            return PinRobot()
        }
        
        func confirmPin(_ pin: String) -> PinRobot {
            enterPin(pin)
                .continueConfirm()
        }
    }

    class ChangePinRobot: CoreElements {
        let verify = Verify()

        required init() {
            super.init()
            staticText(id.changePinStaticTextLabel).waitUntilExists().checkExists()
        }

        func enterPin(_ pin: String) -> ChangePinRobot {
            secureTextField(id.pinTextFieldIdentifier).tap().waitUntilExists().typeText(pin)
            return self
        }

        func continueWithWrongPin() -> ChangePinRobot {
            button(id.confirmButtonIdentifier).tap()
            return self
        }

        func continueSettingPin() -> setPinRobot {
            button(id.confirmButtonIdentifier).tap()
            return setPinRobot()
        }

        class Verify: CoreElements {
            @discardableResult
            func canSeeIncorrectPinError() -> ChangePinRobot {
                let errorMessage = staticText(id.pinTextErrorLabelIdentifier).waitUntilExists().label()
                XCTAssertEqual(errorMessage, LocalString._incorrect_pin)
                return ChangePinRobot()
            }
        }
    }

    class DisablePinRobot: CoreElements {
        let verify = Verify()

        required init() {
            super.init()
            staticText(id.disablePinStaticTextLabel).waitUntilExists().checkExists()
        }

        func enterPin(_ pin: String) -> DisablePinRobot {
            secureTextField(id.pinTextFieldIdentifier).tap().waitUntilExists().clearText().typeText(pin)
            return self
        }

        func continueWithWrongPin() -> DisablePinRobot {
            button(id.confirmButtonIdentifier).tap()
            return self
        }

        func continueWithCorrectPin() -> PinRobot {
            button(id.confirmButtonIdentifier).tap()
            return PinRobot()
        }

        class Verify: CoreElements {
            @discardableResult
            func canSeeIncorrectPinError() -> DisablePinRobot {
                let errorMessage = staticText(id.pinTextErrorLabelIdentifier).waitUntilExists().label()
                var expectedMessage = LocalString._incorrect_pin
                _ = expectedMessage.remove(at: expectedMessage.index(before: expectedMessage.endIndex))
                XCTAssertEqual(errorMessage, expectedMessage)
                return DisablePinRobot()
            }
        }
    }

    class Verify: CoreElements {
        
        @discardableResult
        func isPinEnabled(_ status: Bool) -> PinRobot {
            if status {
                cell(id.pinCellIdentifier).onChild(button(id.checkMarkButtonLabel)).checkExists()
            }
            else {
                cell(id.pinCellIdentifier).onChild(button(id.checkMarkButtonLabel)).checkDoesNotExist()
            }
            return PinRobot()
        }
        
        func appUnlockSuccessfully() -> PinRobot {
            staticText(id.pinStaticTextLabel).waitUntilExists().checkExists()
            return PinRobot()
        }
    }
}
