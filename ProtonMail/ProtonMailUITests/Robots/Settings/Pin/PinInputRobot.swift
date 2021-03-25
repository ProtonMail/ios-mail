//
//  PinInputRobot.swift
//  ProtonMailUITests
//
//  Created by mirage chung on 2020/12/17.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

fileprivate let pinCodeViewIdentifier = "PinCodeViewController.pinCodeView"
fileprivate let pinCodeAttemptStaticTextIdentifier = "PinCodeViewController.attempsLabel"
fileprivate let pinCodeLogoutButtonIdentifier = "PinCodeViewController.backButton"
fileprivate let logoutButtonIdentifier = "Log out"
fileprivate let pinStaticTextZero = "0"
fileprivate let pinStaticTextOne = "1"
fileprivate let pinStaticTextTwo = "2"
fileprivate let pinStaticTextThree = "3"
fileprivate let pinStaticTextFour = "4"
fileprivate let pinStaticTextFive = "5"
fileprivate let pinStaticTextSix = "6"
fileprivate let pinStaticTextSeven = "7"
fileprivate let pinStaticTextEight = "8"
fileprivate let pinStaticTextNine = "9"

fileprivate let pinCreateStaticTextIdentifier = LocalString._general_create_action
fileprivate let pinConfirmStaticTextIdentifier = LocalString._general_confirm_action
fileprivate let okButtonIdentifier = LocalString._general_ok_action
fileprivate let emptyPinStaticTextIdentifier = LocalString._pin_code_cant_be_empty

class PinInputRobot {
    
    var verify: Verify! = nil
    init() {
        verify = Verify()
    }
    
    func enterPinByNumber(_ number: Int) {
        var identifier: String = ""
        switch number {
        case 0:
            identifier = pinStaticTextZero
        case 1:
            identifier = pinStaticTextOne
        case 2:
            identifier = pinStaticTextTwo
        case 3:
            identifier = pinStaticTextThree
        case 4:
            identifier = pinStaticTextFour
        case 5:
            identifier = pinStaticTextFive
        case 6:
            identifier = pinStaticTextSix
        case 7:
            identifier = pinStaticTextSeven
        case 8:
            identifier = pinStaticTextEight
        case 9:
            identifier = pinStaticTextNine
        default: break
        }
        Element.wait.forStaticTextFieldWithIdentifier(identifier, file: #file, line: #line).tap()
    }
    
    @discardableResult
     func enterPin(_ pins: [Int]) -> PinInputRobot {
        for pin in pins {
            enterPinByNumber(pin)
        }
        return PinInputRobot()
    }
    
    func createPin(_ pins: [Int]) -> PinRobot {
        enterPin(pins)
            .create()
            .enterPin(pins)
            .confirm()
        return PinRobot()
    }
    
    func inputIncorrectPin(_ pins: [Int]) -> PinInputRobot {
        enterPin(pins)
            .confirm()
        return PinInputRobot()
    }
    
    func inputCorrectPin(_ pins: [Int]) -> PinRobot {
        enterPin(pins)
            .confirm()
        return PinRobot()
    }
    
    func logout() -> LoginRobot {
        clickLogoutButton()
            .clickLogout()
    }
    
    func clickLogoutButton() -> LogoutDialogRobot {
        Element.wait.forButtonWithIdentifier(pinCodeLogoutButtonIdentifier).tap()
        return LogoutDialogRobot()
    }
    
    func create() -> PinInputRobot {
        Element.wait.forStaticTextFieldWithIdentifier(pinCreateStaticTextIdentifier, file: #file, line: #line).tap()
        return PinInputRobot()
    }
    
    func confirm() {
        Element.wait.forStaticTextFieldWithIdentifier(pinConfirmStaticTextIdentifier, file: #file, line: #line).tap()
    }
    
    func confirmWithEmptyPin() -> PinAlertDialogRobot {
        Element.wait.forStaticTextFieldWithIdentifier(pinConfirmStaticTextIdentifier, file: #file, line: #line).tap()
        return PinAlertDialogRobot()
    }
    
    class LogoutDialogRobot {
        
        func clickLogout() -> LoginRobot {
            Element.wait.forButtonWithIdentifier(logoutButtonIdentifier, file: #file, line: #line).tap()
            return LoginRobot()
        }
    }
    
    class PinAlertDialogRobot {
        
        var verify: Verify! = nil
        init() {
            verify = Verify()
        }
        
        func clickOK() -> PinInputRobot {
            Element.wait.forButtonWithIdentifier(okButtonIdentifier, file: #file, line: #line).tap()
            return PinInputRobot()
        }
        
        class Verify {
            @discardableResult
            func emptyPinErrorMessageShows() -> PinAlertDialogRobot {
                Element.assert.staticTextWithIdentifierExists(emptyPinStaticTextIdentifier)
                return PinAlertDialogRobot()
            }
        }
    }
    
    class Verify {
        
        @discardableResult
        func pinErrorMessageShows(_ count: Int) -> PinInputRobot {
            let errorMessage = String(format: "Incorrect PIN, %d attempts remaining", (10-count))
            Element.wait.forStaticTextFieldWithIdentifier(pinCodeAttemptStaticTextIdentifier).assertWithLabel(errorMessage)
            return PinInputRobot()
        }
    }
}
