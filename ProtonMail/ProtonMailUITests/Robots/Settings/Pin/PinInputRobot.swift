//
//  PinInputRobot.swift
//  Proton MailUITests
//
//  Created by mirage chung on 2020/12/17.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import pmtest
import ProtonCore_TestingToolkit

fileprivate struct id {
    static let pinCodeViewIdentifier = "PinCodeViewController.pinCodeView"
    static let pinCodeAttemptStaticTextIdentifier = "PinCodeViewController.attempsLabel"
    static let pinCodeLogoutButtonIdentifier = "PinCodeViewController.backButton"
    static let logoutButtonIdentifier = "Log out"
    static let pinStaticTextZero = "0"
    static let pinStaticTextOne = "1"
    static let pinStaticTextTwo = "2"
    static let pinStaticTextThree = "3"
    static let pinStaticTextFour = "4"
    static let pinStaticTextFive = "5"
    static let pinStaticTextSix = "6"
    static let pinStaticTextSeven = "7"
    static let pinStaticTextEight = "8"
    static let pinStaticTextNine = "9"
    static let pinCreateStaticTextIdentifier = LocalString._general_create_action
    static let pinConfirmStaticTextIdentifier = LocalString._general_confirm_action
    static let okButtonIdentifier = LocalString._general_ok_action
    static let emptyPinStaticTextIdentifier = LocalString._pin_code_cant_be_empty
}

class PinInputRobot: CoreElements {
    
    var verify = Verify()
    
    func enterPinByNumber(_ number: Int) {
        var identifier: String = ""
        switch number {
        case 0:
            identifier = id.pinStaticTextZero
        case 1:
            identifier = id.pinStaticTextOne
        case 2:
            identifier = id.pinStaticTextTwo
        case 3:
            identifier = id.pinStaticTextThree
        case 4:
            identifier = id.pinStaticTextFour
        case 5:
            identifier = id.pinStaticTextFive
        case 6:
            identifier = id.pinStaticTextSix
        case 7:
            identifier = id.pinStaticTextSeven
        case 8:
            identifier = id.pinStaticTextEight
        case 9:
            identifier = id.pinStaticTextNine
        default: break
        }
        staticText(identifier).tap()
    }
    
    func tapPinSymbolFourTimes() -> PinInputRobot {
        staticText("0").tap().tap().tap().tap()
        return PinInputRobot()
    }
    
    func tapPinSymbol(_ number: String) -> PinInputRobot {
        staticText(number).tap()
        return PinInputRobot()
    }
    
    @discardableResult
     func enterPin(_ pins: [Int]) -> PinInputRobot {
        for pin in pins {
            enterPinByNumber(pin)
        }
        return PinInputRobot()
    }
    
    func inputIncorrectPin() -> PinInputRobot {
        tapPinSymbol("0")
            .confirm()
        return PinInputRobot()
    }

    func inputIncorrectPinNTimes(count: Int) -> LoginRobot {
        typeNTimes(count)
        return LoginRobot()
    }
    
    func inputIncorrectPinNTimesStayLoggedIn(count: Int) -> PinInputRobot {
        typeNTimes(count)
        return PinInputRobot()
    }

    func inputCorrectPin() -> InboxRobot {
        tapPinSymbolFourTimes()
            .confirm()
        return InboxRobot()
    }
    
    func logout() -> LoginRobot {
        clickLogoutButton()
            .clickLogout()
    }
    
    func clickLogoutButton() -> LogoutDialogRobot {
        button(id.pinCodeLogoutButtonIdentifier).tap()
        return LogoutDialogRobot()
    }
    
    func create() -> PinInputRobot {
        staticText(id.pinCreateStaticTextIdentifier).tap()
        return PinInputRobot()
    }
    
    func confirm() {
        staticText(id.pinConfirmStaticTextIdentifier).tap()
    }
    
    func confirmWithEmptyPin() -> PinAlertDialogRobot {
        staticText(id.pinConfirmStaticTextIdentifier).tap()
        return PinAlertDialogRobot()
    }
    
    private func typeNTimes(_ count: Int){
        for _ in 1...count {
            tapPinSymbol("0")
                .confirm()
        }
    }
    
    class LogoutDialogRobot: CoreElements {
        
        func clickLogout() -> LoginRobot {
            button(id.logoutButtonIdentifier).tap()
            return LoginRobot()
        }
    }
    
    class PinAlertDialogRobot: CoreElements {
        
        var verify = Verify()
        
        func clickOK() -> PinInputRobot {
            button(id.okButtonIdentifier).tap()
            return PinInputRobot()
        }
        
        class Verify: CoreElements {
            @discardableResult
            func emptyPinErrorMessageShows() -> PinAlertDialogRobot {
                staticText(id.emptyPinStaticTextIdentifier).wait().checkExists()
                return PinAlertDialogRobot()
            }
        }
    }
    
    class Verify: CoreElements {
        
        @discardableResult
        func pinErrorMessageShows(_ count: Int) -> PinInputRobot {
            let errorMessage = String(format: "Incorrect PIN. %d attempts remaining", (10-count))
            staticText(id.pinCodeAttemptStaticTextIdentifier).hasLabel(errorMessage).wait().checkExists()
            return PinInputRobot()
        }
        
        @discardableResult
        func pinErrorMessageShowsThreeRemainingTries(_ count: Int) -> PinInputRobot {
            let errorMessage = String(format: "%d attempts remaining until secure data wipe!", count)
            staticText(id.pinCodeAttemptStaticTextIdentifier).hasLabel(errorMessage).wait().checkExists()
            return PinInputRobot()
        }
    }
}


