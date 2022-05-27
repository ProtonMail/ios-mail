//
//  SentRobot.swift
//  Proton MailUITests
//
//  Created by denys zelenchuk on 24.07.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import pmtest

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
            staticText(subject).firstMatch().wait().checkExists()
        }
    }
}

