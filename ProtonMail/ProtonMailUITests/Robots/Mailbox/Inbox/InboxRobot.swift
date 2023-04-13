//
//  InboxRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 23.07.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import XCTest
import fusion

fileprivate struct id {
    static let mailboxTableView = "mailboxTableView"
    static let inboxTitleLabel = LocalString._menu_inbox_title
    static let composeButtonLabel = "MailboxViewController.composeBarButtonItem"
    static let buttonSkipTutorial = LocalString._skip_btn_title
    static let skeletonCell = "SkeletonCell"
}

/**
 Represents Inbox view.
*/
class InboxRobot : MailboxRobotInterface {
    
    var verify = Verify()
    required init() {
        super.init()
    }

    @discardableResult
    override func menuDrawer() -> MenuRobot {
        return super.menuDrawer()
    }
    
    override func refreshMailbox() -> InboxRobot {
        super.refreshMailbox()
        cell(id.skeletonCell).firstMatch().waitUntilGone()
        return self
    }
    
    func backgroundAppWithoutPin() -> InboxRobot {
        XCUIDevice.shared.press(.home)
        sleep(3)    //It's always more stable when there is a small gap between background and foreground
        return self
    }
    
    func activateAppWithoutPin() -> InboxRobot {
        XCUIApplication().activate()
        return self
    }
    
    /**
     Contains all the validations that can be performed by InboxRobot.
    */
    class Verify: MailboxRobotVerifyInterface {
        
        @discardableResult
        func inboxShown(time: TimeInterval = 10.0) -> InboxRobot {
            button(id.composeButtonLabel).waitUntilExists(time: time).checkExists()
            return InboxRobot()
        }
    }
}
