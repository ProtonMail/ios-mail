//
//  SentRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 24.07.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import pmtest

fileprivate struct id {
    static func messageCellIdentifier(_ subject: String) -> String { return "NewMailboxMessageCell.\(subject)" }
}

/**
 Represents Sent view.
*/
class SentRobot : MailboxRobotInterface {
    
    var verify = Verify()

    override func menuDrawer() -> MenuRobot {
        return super.menuDrawer()
    }
    
    override func refreshMailbox() -> SentRobot {
        super.refreshMailbox()
        return self
    }
    
    /**
     Contains all the validations that can be performed by SentRobot.
    */
    class Verify: MailboxRobotVerifyInterface {
        
        func messageWithSubjectExists(_ subject: String) {
            cell(id.messageCellIdentifier(subject)).swipeUpUntilVisible().checkExists()
        }
    }
}

