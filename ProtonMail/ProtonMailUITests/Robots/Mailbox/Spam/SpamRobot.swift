//
//  SpamRobot.swift
//  ProtonMailUITests
//
//  Created by mirage chung on 2020/12/4.
//  Copyright © 2020 ProtonMail. All rights reserved.
//



fileprivate let mailboxMoreButtonIdentifier = "MailboxViewController.moreBarButtonItem"
fileprivate let emptyFolderButtonIdentifier = "Empty folder"
fileprivate let spamStaticTextIdentifier = "MailboxViewController.navigationTitleLabel"

class SpamRobot: MailboxRobotInterface {
    
    var verify: Verify! = nil
    override init() {
        super.init()
        let label = LocalString._menu_spam_title
        Element.wait.forStaticTextFieldWithIdentifier(spamStaticTextIdentifier, file:#file, line: #line).assertWithLabel(label)
        verify = Verify(parent: self)
    }
    
    func clearSpamFolder() -> SpamRobot {
        moreOptions()
            .emptyFolder()
            .emptyFolderDialog()
    }
    
    private func moreOptions() -> SpamRobot {
        Element.wait.forButtonWithIdentifier(mailboxMoreButtonIdentifier, file: #file, line: #line).tap()
        return SpamRobot()
    }

    private func emptyFolder() -> SpamDialogRobot {
        Element.wait.forButtonWithIdentifier(emptyFolderButtonIdentifier, file: #file, line: #line).tap()
        return SpamDialogRobot()
    }
    
    class SpamDialogRobot {
        func emptyFolderDialog() -> SpamRobot {
            Element.wait.forButtonWithIdentifier(emptyFolderButtonIdentifier, file: #file, line: #line).tap()
            return SpamRobot()
        }
    }
    /**
     * Contains all the validations that can be performed by [Spam].
     */
    class Verify : MailboxRobotVerifyInterface {
        unowned let spamRobot: SpamRobot
        init(parent: SpamRobot) { spamRobot = parent }
        
        func messageWithSubjectExists(_ subject: String) {
            Element.wait.forStaticTextFieldWithIdentifier(subject)
        }
    }
}
