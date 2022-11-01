//
//  SpamRobot.swift
//  ProtonMailUITests
//
//  Created by mirage chung on 2020/12/4.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import pmtest

fileprivate struct id {
    static let mailboxMoreButtonIdentifier = "MailboxViewController.moreBarButtonItem"
    static let emptyFolderButtonIdentifier = "Empty folder"
    static let spamStaticTextIdentifier = "MailboxViewController.navigationTitleLabel"
    static let mailTitileIdentifier = "mailboxMessageCell.titleLabel"
}

class SpamRobot: MailboxRobotInterface {
    
    var verify = Verify()
    
    required init() {
        super.init()
        let label = LocalString._menu_spam_title
        staticText(id.spamStaticTextIdentifier).wait().checkHasLabel(label)
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
        button(id.emptyFolderButtonIdentifier).tap()
        return SpamDialogRobot()
    }
    
    class SpamDialogRobot: CoreElements {
        
        func emptyFolderDialog() -> SpamRobot {
            button(id.emptyFolderButtonIdentifier).tap()
            return SpamRobot()
        }
    }
    /**
     * Contains all the validations that can be performed by [Spam].
     */
    class Verify : MailboxRobotVerifyInterface {
        
        func messageWithSubjectExists(_ subject: String) {
            staticText(id.mailTitileIdentifier).containsLabel(subject).wait().checkExists()
        }
    }
}
