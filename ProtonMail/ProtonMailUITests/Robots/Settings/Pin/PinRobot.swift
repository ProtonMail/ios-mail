//
//  PinRobot.swift
//  Proton MailUITests
//
//  Created by mirage chung on 2020/12/17.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import XCTest
import pmtest

fileprivate struct id {
    static let pinCellIdentifier = "SettingsLockView.pinCodeCell"
    static let nonePinCellIdentifier = "SettingsLockView.nonCell"
    static let pinStaticTextLabel = LocalString._app_pin
    static let setPinStaticTextLabel =  LocalString._pin_code_setup1_title
    static let repeatPinStaticTextLabel = LocalString._pin_code_setup2_title
    static let noneAutoLockButtonLabel = LocalString._general_none
    static let everyTimeLockButtonLabel = LocalString._settings_every_time_enter_app
    static let backToSettingsNavBarButtonIdentifier = LocalString._menu_settings_title
    static let usePinSwitchIdentifier = "Use PIN code"
    static let autoLockCellIdentifier = "SettingsCell.Auto-Lock_Timer"
    static let pinTimerCellIdentifier = "SettingsGeneralCell.Timing"
    static let addPinTextFieldIdentifier = "PinCodeSetUpViewController.textField"
    static let nextButtonIdentifier = "PinCodeSetUpViewController.nextButton"
    static let confirmPinTextFieldIdentifier = "PinCodeConfirmationViewController.textField"
    static let confirmButtonIdentifier = "PinCodeConfirmationViewController.confirmButton"
    static let checkMarkButtonLabel = "checkmark"
}

class PinRobot: CoreElements {
    
    var verify = Verify()
    
    required init() {
        super.init()
        staticText(id.pinStaticTextLabel).wait().checkExists()
    }
    
    func enablePin() -> setPinRobot {
        cell(id.pinCellIdentifier).tap()
        return setPinRobot()
    }
    
    func navigateUpToSettings() -> SettingsRobot {
        button(id.backToSettingsNavBarButtonIdentifier).tap()
        return SettingsRobot()
    }
    
    func pinTimmer() -> AutoLockTimeRobot {
        cell(id.pinTimerCellIdentifier).tap()
        return AutoLockTimeRobot()
    }
    
    @discardableResult
    func usePin() -> PinInputRobot {
        swittch(id.pinCellIdentifier).tap()
        return PinInputRobot()
    }
    
    @discardableResult
    func disablePin() -> PinRobot {
        cell(id.nonePinCellIdentifier).tap()
        return PinRobot()
    }
    
    func backgroundApp() -> PinRobot {
        XCUIDevice.shared.press(.home)
        sleep(3)    //It's always more stable when there is a small gap between background and foreground
        return PinRobot()
    }
    
    func foregroundApp() -> PinInputRobot {
        XCUIApplication().launch()
        return PinInputRobot()
    }
    
    func activateAppWithPin() -> PinInputRobot {
        XCUIApplication().activate()
        return PinInputRobot()
    }
    
    func activateAppWithoutPin() -> PinRobot {
        XCUIApplication().activate()
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
            staticText(id.setPinStaticTextLabel).wait().checkExists()
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
            staticText(id.repeatPinStaticTextLabel).wait().checkExists()
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
            staticText(id.pinStaticTextLabel).wait().checkExists()
        }
    }
}
