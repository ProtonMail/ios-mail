//
//  MessageDetailRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 13.11.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import pmtest

fileprivate struct id {
    /// Navigation Bar buttons
    static let labelNavBarButtonIdentifier = "PMToolBarView.labelAsButton"
    static let folderNavBarButtonIdentifier = "PMToolBarView.moveToButton"
    static let trashNavBarButtonIdentifier = "PMToolBarView.trashButton"
    static let moreNavBarButtonIdentifier = "PMToolBarView.moreButton"
    static let backToInboxNavBarButtonIdentifier = LocalString._menu_inbox_title
    static let moveToSpamButtonIdentifier = LocalString._move_to_spam
    static let moveToArchiveButtonIdentifier = LocalString._locations_move_archive_action
    static let backToSearchResultButtonIdentifier = LocalString._general_back_action

    /// Reply/Forward buttons
    static let replyTextLabel = LocalString._general_reply_button
    static let replyAllTextLabel = LocalString._general_replyall_button
    static let replyButtonIdentifier = "MessageContainerViewController.replyButton"
    static let replyAllButtonIdentifier = "MessageContainerViewController.replyAllButton"
    static let forwardButtonIdentifier = "MessageContainerViewController.forwardButton"
}

/*
 MessageRobot class contains actions and verifications for Message detail view funcctionality.
 */
class MessageRobot: CoreElements {
    
    func addMessageToFolder(_ folderName: String) -> InboxRobot {
        openFoldersModal()
            .selectFolder(folderName)
            .tapDoneSelectingFolderButton()
    }
    
    func assignLabelToMessage(_ folderName: String) -> MessageRobot {
        openLabelsModal()
            .selectFolder(folderName)
            .tapDoneSelectingLabelButton()
    }
    
    func createFolder(_ folderName: String) -> MoveToFolderRobotInterface {
        openFoldersModal()
            .clickAddFolder()
            .typeFolderName(folderName)
            .tapDoneCreatingButton(robot: MoveToFolderRobotInterface.self)
    }
    
    func createLabel(_ folderName: String) -> MoveToFolderRobot {
        openLabelsModal()
            .clickAddLabel()
            .typeFolderName(folderName)
            .tapDoneCreatingButton(robot: MoveToFolderRobot.self)
    }
    
    func clickMoveToSpam() -> MailboxRobotInterface {
        moreOptions().moveToSpam()
    }
    
    func clickMoveToArchive() -> MailboxRobotInterface {
        moreOptions().moveToArchive()
    }
    
    func moveToTrash() -> InboxRobot {
        button(id.trashNavBarButtonIdentifier).tap()
        return InboxRobot()
    }
    
    func navigateBackToInbox() -> InboxRobot {
        button(id.backToInboxNavBarButtonIdentifier).tap()
        return InboxRobot()
    }
    
    func navigateBackToSearchResult() -> SearchRobot {
        button(id.backToSearchResultButtonIdentifier).tap()
        return SearchRobot()
    }
    
    func openFoldersModal() -> MoveToFolderRobot {
        button(id.folderNavBarButtonIdentifier).tap()
        return MoveToFolderRobot()
    }
    
    func openLabelsModal() -> MoveToFolderRobot {
        button(id.labelNavBarButtonIdentifier).tap()
        return MoveToFolderRobot()
    }
    
    func moreOptions() -> MessageMoreOptions {
        button(id.moreNavBarButtonIdentifier).tap()
        return MessageMoreOptions()
    }

    func reply() -> ComposerRobot {
        staticText(id.replyTextLabel).tap()
        return ComposerRobot()
    }

    func replyAll() -> ComposerRobot {
        staticText(id.replyAllTextLabel).tap()
        return ComposerRobot()
    }

    func forward() -> ComposerRobot {
        button(id.forwardButtonIdentifier).tap()
        return ComposerRobot()
    }

    func navigateBackToLabelOrFolder(_ folder: String) -> LabelFolderRobot {
        button(folder).tap()
        return LabelFolderRobot()
    }
    
    class MessageMoreOptions: CoreElements {

        func moveToSpam() -> MailboxRobotInterface {
            cell(id.moveToSpamButtonIdentifier).tap()
            return MailboxRobotInterface()
        }
        
        func moveToArchive() -> MailboxRobotInterface {
            button(id.moveToArchiveButtonIdentifier).tap()
            return MailboxRobotInterface()
        }
    }
    
    internal class MoveToFolderRobot: MoveToFolderRobotInterface {

        override func clickAddFolder() -> AddNewFolderRobot {
            super.clickAddFolder()
            return AddNewFolderRobot()
        }
        
        override func clickAddLabel() -> AddNewFolderRobot {
            super.clickAddLabel()
            return AddNewFolderRobot()
        }
        
        override func selectFolder(_ folderName: String) -> MoveToFolderRobot {
            super.selectFolder(folderName)
            return MoveToFolderRobot()
        }
    }
    
    class AddNewFolderRobot: MoveToFolderRobotInterface {

        override func typeFolderName(_ folderName: String) -> AddNewFolderRobot {
            super.typeFolderName(folderName)
            return self
        }
        
        override func selectFolderColorByIndex(_ index: Int) -> AddNewFolderRobot {
            super.selectFolderColorByIndex(index)
            return self
        }
        
        override func clickCreateFolderButton() -> MoveToFolderRobot {
            super.clickCreateFolderButton()
            return MoveToFolderRobot()
        }
        
        override func tapKeyboardDoneButton() -> AddNewFolderRobot {
            super.tapKeyboardDoneButton()
            return AddNewFolderRobot()
        }
    }
}
