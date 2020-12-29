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
    
    func backgroundApp() -> PinRobot{
        XCUIDevice.shared.press(.home)
        return PinRobot()
    }
    
    func foregroundApp() -> PinInputRobot{
        XCUIApplication().launch()
        return PinInputRobot()
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
