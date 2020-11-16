//
//  SentRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 24.07.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import XCTest

/**
 Represents Sent view.
*/
class SentRobot : MailboxRobotInterface {
    
    var verify: Verify! = nil
    override init() {
        super.init()
        verify = Verify(parent: self)
    }

    override func menuDrawer() -> MenuRobot {
        return super.menuDrawer()
    }

    override func swipeLeftMessageAtPosition(_ position: Int) -> SentRobot {
        super.swipeLeftMessageAtPosition(position)
        return self
    }
    
    /**
     Contains all the validations that can be performed by SentRobot.
    */
    class Verify: MailboxRobotVerifyInterface {
        unowned let sentRobot: SentRobot
        init(parent: SentRobot) { sentRobot = parent }
        
        func messageWithSubjectExists(_ subject: String) {
            Element.assert.staticTextWithIdentifierExists(subject)
        }
    }
}

