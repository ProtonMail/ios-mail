//
//  MoveToFolderRobotProtocol.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 23.07.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

/// Move to folder dialog identifiers
fileprivate let addFolderButtonIdentifier = "LablesViewController.addFolderButton"
fileprivate let addLabelButtonIdentifier = "LablesViewController.addLabelButton"
fileprivate let applyMoveToFolderButtonIdentifier = "LablesViewController.applyButton"
fileprivate let cancelMoveToFolderButtonIdentifier = "LablesViewController.cancelButton"
fileprivate func folderCellIdentifier(_ folderName: String) -> String { return "LabelTableViewCell.\(folderName)".replacingOccurrences(of: " ", with: "_") }

/// Add new folder dialog identifiers
fileprivate let folderNameTextFieldIdentifier = "LableEditViewController.newLabelInput"
fileprivate let cancelAddFolderButtonIdentifier = "LableEditViewController.cancelButton"
fileprivate let applyAddFolderButtonIdentifier = "LableEditViewController.applyButton"
fileprivate let colorCollectionViewIdentifier = "LableEditViewController.collectionView"
fileprivate let doneKyboardButtonIdentifier = LocalString._general_done_button.lowercased()

/**
 Parent class for Label and Folder dialogs in all the Mailbox Robot classes like Inbox, Sent, Trash, etc.
*/
class MoveToFolderRobotInterface {
    
    @discardableResult
    func clickAddFolder() -> MoveToFolderRobotInterface {
        Element.wait.forButtonWithIdentifier(addFolderButtonIdentifier, file: #file, line: #line).tap()
        return self
    }
    
    @discardableResult
    func clickAddLabel() -> MoveToFolderRobotInterface {
        Element.wait.forButtonWithIdentifier(addLabelButtonIdentifier, file: #file, line: #line).tap()
        return self
    }
    
    @discardableResult
    func selectFolder(_ folderName: String) -> MoveToFolderRobotInterface {
        Element.wait.forCellWithIdentifier(folderCellIdentifier(folderName), file: #file, line: #line).tap()
        return self
    }
    
    @discardableResult
    func clickApplyButtonAndReturnToInbox() -> MailboxRobotInterface {
        Element.wait.forButtonWithIdentifier(applyMoveToFolderButtonIdentifier, file: #file, line: #line).tap()
        return MailboxRobotInterface()
    }
    
    @discardableResult
    func clickLabelApplyButton() -> MessageRobot {
        Element.wait.forButtonWithIdentifier(applyMoveToFolderButtonIdentifier, file: #file, line: #line).tap()
        return MessageRobot()
    }
    
    @discardableResult
    func typeFolderName(_ folderName: String) -> MoveToFolderRobotInterface {
        Element.wait.forTextFieldWithIdentifier(folderNameTextFieldIdentifier, file: #file, line: #line).typeText(folderName)
        return self
    }
    
    @discardableResult
    func selectFolderColorByIndex(_ index: Int) -> MoveToFolderRobotInterface {
        Element.wait.forCollectionViewWithIdentifier(colorCollectionViewIdentifier, file: #file, line: #line).clickCellByIndex(index)
        return self
    }
    
    @discardableResult
    func clickCreateFolderButton() -> MoveToFolderRobotInterface {
        Element.wait.forButtonWithIdentifier(applyAddFolderButtonIdentifier, file: #file, line: #line).tap()
        return self
    }
    
    @discardableResult
    func tapKeyboardDoneButton() -> MoveToFolderRobotInterface {
        Element.wait.forButtonWithIdentifier(doneKyboardButtonIdentifier, file: #file, line: #line).tap()
        return self
    }
    
    func moveToExistingFolder(name: String) -> MoveToFolderRobotInterface {
        //TODO:: add implementation
        return self
    }
}
