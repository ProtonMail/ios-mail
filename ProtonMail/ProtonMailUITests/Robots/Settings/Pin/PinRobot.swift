//
//  PinRobot.swift
//  ProtonMailUITests
//
//  Created by mirage chung on 2020/12/17.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

fileprivate let pinSwitchIdentifier = LocalString._enable_pin
fileprivate let usePinSwitchIdentifier = "Use PIN code"
fileprivate let pinStaticTextIdentifier = LocalString._pin
fileprivate let autoLockCellIdentifier = "SettingsCell.Auto-Lock_Timer"
fileprivate let noneAutoLockButtonLabel = LocalString._general_none
fileprivate let everyTimeLockButtonLabel = LocalString._settings_every_time_enter_app
fileprivate let backToSettingsNavBarButtonIdentifier = LocalString._menu_settings_title

import XCTest

class PinRobot {
    
    var verify: Verify! = nil
    init() {
        verify = Verify()
        Element.wait.forStaticTextFieldWithIdentifier(pinStaticTextIdentifier, file: #file, line: #line)
    }
    
    @discardableResult
    func enablePin() -> PinRobot {
        Element.swittch.tapByIdentifier(pinSwitchIdentifier)
        return PinRobot()
    }
    
    func enableAndSetPin(_ pins: [Int]) -> PinRobot {
        enablePin()
            .usePin()
            .createPin(pins)
    }
    
    func navigateUpToSettings() -> SettingsRobot {
        Element.wait.forButtonWithIdentifier(backToSettingsNavBarButtonIdentifier, file: #file, line: #line).tap()
        return SettingsRobot()
    }
    
    func autoLockTimer() -> AutoLockTimeRobot {
        Element.wait.forCellWithIdentifier(autoLockCellIdentifier).tap()
        return AutoLockTimeRobot()
    }
    
    @discardableResult
    func usePin() -> PinInputRobot {
        Element.swittch.tapByIdentifier(usePinSwitchIdentifier)
        return PinInputRobot()
    }
    
    @discardableResult
    func disablePin() -> PinRobot {
        Element.swittch.tapByIdentifier(usePinSwitchIdentifier)
        return PinRobot()
    }
    
    func backgroundApp() -> PinRobot {
        XCUIDevice.shared.press(.home)
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
    
    class AutoLockTimeRobot {
        
        func selectAutoLockNone() -> PinRobot {
            Element.wait.forButtonWithIdentifier(noneAutoLockButtonLabel).tap()
            return PinRobot()
        }
        
        func selectAutolockEveryTime() -> PinRobot {
            Element.wait.forButtonWithIdentifier(everyTimeLockButtonLabel).tap()
            return PinRobot()
        }
    }

    class Verify {
        
        @discardableResult
        func isUsePinToggleOn(_ status: Bool) -> PinRobot {
            let status = Element.swittch.isEnabledByIdentifier(usePinSwitchIdentifier)
            if status {
                XCTAssertTrue(status)
            }
            else {
                XCTAssertFalse(status)
            }
            return PinRobot()
        }
        
        func appUnlockSuccessfully() {
            Element.wait.forStaticTextFieldWithIdentifier(pinStaticTextIdentifier)
        }
    }
    
}
