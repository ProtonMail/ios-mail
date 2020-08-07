//
//  ComposerRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 24.07.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//
import XCTest

fileprivate let sendButtonLabel = "Send"
fileprivate let toStaticTextLabel = "To"
fileprivate let fromStaticTextLabel = "From"
fileprivate let subjectStaticTextLabel = "Subject"

/**
 Represents Composer view.
*/
class ComposerRobot {
    
    var verify: Verify! = nil
    init() { verify = Verify(parent: self) }
    
    func sendMessage(to: String, subject: String) -> InboxRobot {
        //TODO:: add implementation
        return InboxRobot()
    }
    
    func sendMessage(to: String, cc: String, subject: String) -> InboxRobot {
        //TODO:: add implementation
        return InboxRobot()
    }
    
    func sendMessage(to: String, cc: String, bcc: String, subject: String) -> InboxRobot {
        //TODO:: add implementation
        return InboxRobot()
    }
    
    func send() -> InboxRobot {
        Element.button.tapByIdentifier(sendButtonLabel)
        return InboxRobot()
    }
    
    func from(_ email: String) -> ComposerRobot {
        Element.button.tapByIdentifier(fromStaticTextLabel).typeText(email)
        return self
    }
    
    func toRecipients(_ email: String) -> ComposerRobot {
        Element.staticText.tapByIdentifier(toStaticTextLabel).typeText(email)
        return self
    }
    
    func subject(_ subject: String) -> ComposerRobot {
        Element.staticText.tapByIdentifier(subjectStaticTextLabel)
        return self
    }
    
    /**
     Contains all the validations that can be performed by ComposerRobot.
    */
    class Verify {
        unowned let composerRobot: ComposerRobot
        init(parent: ComposerRobot) { composerRobot = parent }
    }
}

