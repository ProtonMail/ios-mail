//
//  SpamRobot.swift
//  ProtonMailUITests
//
//  Created by mirage chung on 2020/12/4.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import fusion

fileprivate struct id {
    static let mailboxMoreButtonIdentifier = "MailboxViewController.ellipsisMenuBarItem"
    static let emptySpamButtonIdentifier = LocalString._empty_spam
    static let spamStaticTextIdentifier = "MailboxViewController.navigationTitleLabel"
    static let confirmDeleteButtonText = LocalString._general_delete_action
}

class SpamRobot: MailboxRobotInterface {
    
    var verify = Verify()
    
    required init() {
        super.init()
    }
    
    func clearSpamFolder() -> SpamRobot {
        moreOptions()
            .emptyFolder()
            .emptyFolderDialog()
    }
    
    private func moreOptions() -> SpamRobot {
        button(id.mailboxMoreButtonIdentifier).tap()
        return SpamRobot()
    }

    private func emptyFolder() -> SpamDialogRobot {
        button(id.emptySpamButtonIdentifier).tap()
        return SpamDialogRobot()
    }
    
    class SpamDialogRobot: CoreElements {
        
        func emptyFolderDialog() -> SpamRobot {
            button(id.confirmDeleteButtonText).tap()
            return SpamRobot()
        }
    }
    /**
     * Contains all the validations that can be performed by [Spam].
     */
    class Verify : MailboxRobotVerifyInterface {
        
    }
}
