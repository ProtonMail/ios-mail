//
//  DraftsRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 08.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import XCTest

fileprivate func messageCellIdentifier(_ subject: String) -> String { return subject.replacingOccurrences(of: " ", with: "_") }

/**
 * [DraftsRobot] implements [MailboxRobotInterface],
 * contains actions and verifications for Drafts composer functionality.
 */
class DraftsRobot : MailboxRobotInterface {
    
    var verify: Verify! = nil
    override init() { verify = Verify()}

    override func swipeLeftMessageAtPosition(_ position: Int) -> DraftsRobot {
        super.swipeLeftMessageAtPosition(position)
        return self
    }

    override func longClickMessageOnPosition(_ position: Int) -> DraftsRobot {
        super.longClickMessageOnPosition(position)
        return self
    }

    override func deleteMessageWithSwipe(_ position: Int) -> DraftsRobot {
        super.deleteMessageWithSwipe(position)
        return self
    }
    
    override func searchBar() -> SearchRobot {
        return super.searchBar()
    }

    func moreOptions() -> DraftsRobot {

        return self
    }

    func emptyFolder() -> DraftsRobot {

        return self
    }

    func confirm() -> DraftsRobot {

        return self
    }

    func clickDraftBySubject(_ subject: String) -> ComposerRobot {
        super.clickMessageBySubject(messageCellIdentifier(subject))
        return ComposerRobot()
    }
    
    func clickDraftByIndex(_ index: Int) -> ComposerRobot {
        super.clickMessageByIndex(index)
        return ComposerRobot()
    }

    /**
     * Contains all the validations that can be performed by [Drafts].
     */
    class Verify : MailboxRobotVerifyInterface {

        func draftMessageSaved(_ draftSubject: String?) -> DraftsRobot {
            return DraftsRobot()
        }
        
        func messageWithSubjectExists(_ subject: String) {
            Element.wait.forStaticTextFieldWithIdentifier(subject)
        }
        
        func messageWithSubjectAndRecipientExists(_ subject: String, _ recipient: String) {
            
        }
    }
}

