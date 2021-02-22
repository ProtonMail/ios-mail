//
//  InboxRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 23.07.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import XCTest

fileprivate let mailboxTableView = "mailboxTableView"

/**
 Represents Inbox view.
*/
class InboxRobot : MailboxRobotInterface {
    
    var verify: Verify! = nil
    
    override init() {
        super.init()
        verify = Verify(parent: self)
    }

    @discardableResult
    override func menuDrawer() -> MenuRobot {
        return super.menuDrawer()
    }
    
    override func swipeLeftMessageAtPosition(_ position: Int) -> InboxRobot {
        super.swipeLeftMessageAtPosition(position)
        return self
    }
    
    /**
     Contains all the validations that can be performed by InboxRobot.
    */
    class Verify: MailboxRobotVerifyInterface {
        
        unowned let inboxRobot: InboxRobot
        init(parent: InboxRobot) { inboxRobot = parent }
        
        @discardableResult
        func loginSuccessful() -> InboxRobot {
            Element.wait.forButtonWithIdentifier(composeButtonLabel, file: #file, line: #line)
            return InboxRobot()
        }
    }
}
