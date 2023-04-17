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
    static let pinCellIdentifier = "SettingsLockView.pinCodeCell"
    static let nonePinCellIdentifier = "SettingsLockView.nonCell"
    static let pinStaticTextLabel = LocalString._app_pin
    static let setPinStaticTextLabel =  LocalString._pin_code_setup1_title
    static let repeatPinStaticTextLabel = LocalString._pin_code_setup2_title
    static let appKeySwitchIdentifier = "SettingsLockView.appKeySwitch"
    static let appKeyConfirmationAlertButtonLabel = "Continue"
    static let noneAutoLockButtonLabel = LocalString._general_none
    static let everyTimeLockButtonLabel = LocalString._settings_every_time_enter_app
    static let backToSettingsNavBarButtonIdentifier = LocalString._menu_settings_title
    static let usePinSwitchIdentifier = "Use PIN code"
    static let autoLockCellIdentifier = "SettingsCell.Auto-Lock_Timer"
    static let pinTimerCellIdentifier = "SettingsGeneralCell.Timing"
    static let addPinTextFieldIdentifier = "PinCodeSetUpViewController.passwordTextField.textField"
    static let nextButtonIdentifier = "PinCodeSetUpViewController.nextButton"
    static let confirmPinTextFieldIdentifier = "PinCodeConfirmationViewController.passwordTextField.textField"
    static let confirmButtonIdentifier = "PinCodeConfirmationViewController.confirmButton"
    static let checkMarkButtonLabel = "checkmark"
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
    
    func navigateUpToSettings() -> SettingsRobot {
        button(id.backToSettingsNavBarButtonIdentifier).tap()
        return SettingsRobot()
    }

    @available(*, deprecated, renamed: "pinTimer")
    func pinTimmer() -> AutoLockTimeRobot {
        pinTimer()
    }

    func pinTimer() -> AutoLockTimeRobot {
        cell(id.pinTimerCellIdentifier).tap()
        return AutoLockTimeRobot()
    }

    func enableAppKey() -> PinRobot {
        swittch(id.appKeySwitchIdentifier).tap()
        button(id.appKeyConfirmationAlertButtonLabel).tap()
        return PinRobot()
    }
    
    @discardableResult
    func disablePin() -> PinRobot {
        cell(id.nonePinCellIdentifier).tap()
        return PinRobot()
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
            secureTextField(id.addPinTextFieldIdentifier).typeText(pin)
            return self
        }
        
        func continueSettingPin() -> RepeatPinRobot {
            button(id.nextButtonIdentifier).tap()
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
            secureTextField(id.confirmPinTextFieldIdentifier).tap().typeText(pin)
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
        
        func appUnlockSuccessfully() {
            staticText(id.pinStaticTextLabel).waitUntilExists().checkExists()
        }
    }
}
