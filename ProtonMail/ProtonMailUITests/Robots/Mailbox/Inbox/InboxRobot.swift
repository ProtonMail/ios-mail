//
//  InboxRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 23.07.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import XCTest
import pmtest

fileprivate struct id {
    static let mailboxTableView = "mailboxTableView"
    static let inboxTitleLabel = LocalString._menu_inbox_title
    static let composeButtonLabel = "Compose"
    static let buttonSkipTutorial = LocalString._skip_btn_title
}

/**
 Represents Inbox view.
*/
class InboxRobot : MailboxRobotInterface {
    
    var verify = Verify()

    @discardableResult
    override func menuDrawer() -> MenuRobot {
        return super.menuDrawer()
    }
    
    override func refreshMailbox() -> InboxRobot {
        super.refreshMailbox()
        return self
    }
    
    public func skipTutorialIfNeeded() -> InboxRobot {
        //check only once in the whole test run
        if(XCTestCase.tutorialSkipped == false && button(id.buttonSkipTutorial).wait().exists()) {
            button(id.buttonSkipTutorial).tap()
        }
        XCTestCase.tutorialSkipped = true
        return self
    }
    
    /**
     Contains all the validations that can be performed by InboxRobot.
    */
    class Verify: MailboxRobotVerifyInterface {
        
        @discardableResult
        func inboxShown() -> InboxRobot {
            button(id.composeButtonLabel).wait().checkExists()
            return InboxRobot()
        }
    }
}
