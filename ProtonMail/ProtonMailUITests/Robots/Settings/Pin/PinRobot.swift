//
//  PinRobot.swift
//  ProtonMailUITests
//
//  Created by mirage chung on 2020/12/17.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import XCTest
import pmtest

fileprivate struct id {
    static let pinSwitchIdentifier = LocalString._enable_pin
    static let pinStaticTextIdentifier = LocalString._pin
    static let noneAutoLockButtonLabel = LocalString._general_none
    static let everyTimeLockButtonLabel = LocalString._settings_every_time_enter_app
    static let backToSettingsNavBarButtonIdentifier = LocalString._menu_settings_title
    static let usePinSwitchIdentifier = "Use PIN code"
    static let autoLockCellIdentifier = "SettingsCell.Auto-Lock_Timer"
}

class PinRobot: CoreElements {
    
    var verify = Verify()
    
    required init() {
        super.init()
        staticText(id.pinStaticTextIdentifier).wait().checkExists()
    }
    
    @discardableResult
    func enablePin() -> PinRobot {
        swittch(id.pinSwitchIdentifier).tap()
        return PinRobot()
    }
    
    func enableAndSetPin(_ pins: [Int]) -> PinRobot {
        enablePin()
            .usePin()
            .createPin(pins)
    }
    
    func navigateUpToSettings() -> SettingsRobot {
        button(id.backToSettingsNavBarButtonIdentifier).tap()
        return SettingsRobot()
    }
    
    func autoLockTimer() -> AutoLockTimeRobot {
        cell(id.autoLockCellIdentifier).tap()
        return AutoLockTimeRobot()
    }
    
    @discardableResult
    func usePin() -> PinInputRobot {
        swittch(id.pinSwitchIdentifier).tap()
        return PinInputRobot()
    }
    
    @discardableResult
    func disablePin() -> PinRobot {
        swittch(id.usePinSwitchIdentifier).tap()
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

    class Verify: CoreElements {
        
        @discardableResult
        func isUsePinToggleOn(_ status: Bool) -> PinRobot {
            let status = Element.swittch.isEnabledByIdentifier(id.usePinSwitchIdentifier)
            if status {
                XCTAssertTrue(status)
            }
            else {
                XCTAssertFalse(status)
            }
            return PinRobot()
        }
        
        func appUnlockSuccessfully() {
            staticText(id.pinStaticTextIdentifier).wait().checkExists()
        }
    }
}
