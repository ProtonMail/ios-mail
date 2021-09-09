//
//  MoveToFolderRobotProtocol.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 23.07.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import pmtest

fileprivate struct id {
    /// Move to folder dialog identifiers
    static let addFolderButtonIdentifier = "LabelsViewController.addFolderButton"
    static let addLabelButtonIdentifier = "LabelsViewController.addLabelButton"
    static let applyMoveToFolderButtonIdentifier = "LabelsViewController.applyButton"
    static let cancelMoveToFolderButtonIdentifier = "LabelsViewController.cancelButton"
    static func folderCellIdentifier(_ folderName: String) -> String { return "LabelTableViewCell.\(folderName)".replacingOccurrences(of: " ", with: "_") }

    /// Add new folder dialog identifiers
    static let folderNameTextFieldIdentifier = "LabelEditViewController.newLabelInput"
    static let cancelAddFolderButtonIdentifier = "LabelEditViewController.cancelButton"
    static let applyAddFolderButtonIdentifier = "LabelEditViewController.applyButton"
    static let colorCollectionViewIdentifier = "LabelEditViewController.collectionView"
    static let doneKyboardButtonIdentifier = LocalString._general_done_button.lowercased()
}

/**
 Parent class for Label and Folder dialogs in all the Mailbox Robot classes like Inbox, Sent, Trash, etc.
*/
class MoveToFolderRobotInterface: CoreElements {
    
    @discardableResult
    func clickAddFolder() -> MoveToFolderRobotInterface {
        button(id.addFolderButtonIdentifier).tap()
        return self
    }
    
    @discardableResult
    func clickAddLabel() -> MoveToFolderRobotInterface {
        button(id.addLabelButtonIdentifier).tap()
        return self
    }
    
    @discardableResult
    func selectFolder(_ folderName: String) -> MoveToFolderRobotInterface {
        cell(id.folderCellIdentifier(folderName)).tap()
        return self
    }
    
    @discardableResult
    func clickApplyButtonAndReturnToInbox() -> MailboxRobotInterface {
        button(id.applyMoveToFolderButtonIdentifier).tap()
        return MailboxRobotInterface()
    }
    
    @discardableResult
    func clickLabelApplyButton() -> MessageRobot {
        button(id.applyMoveToFolderButtonIdentifier).tap()
        return MessageRobot()
    }
    
    @discardableResult
    func typeFolderName(_ folderName: String) -> MoveToFolderRobotInterface {
        textField(id.folderNameTextFieldIdentifier).typeText(folderName)
        return self
    }
    
    @discardableResult
    func selectFolderColorByIndex(_ index: Int) -> MoveToFolderRobotInterface {
        collectionView(id.colorCollectionViewIdentifier).onChild(cell().byIndex(index)).tap()
        return self
    }
    
    @discardableResult
    func clickCreateFolderButton() -> MoveToFolderRobotInterface {
        button(id.applyAddFolderButtonIdentifier).tap()
        return self
    }
    
    @discardableResult
    func tapKeyboardDoneButton() -> MoveToFolderRobotInterface {
        button(id.doneKyboardButtonIdentifier).tap()
        return self
    }
    
    func moveToExistingFolder(name: String) -> MoveToFolderRobotInterface {
        //TODO:: add implementation
        return self
    }
}
