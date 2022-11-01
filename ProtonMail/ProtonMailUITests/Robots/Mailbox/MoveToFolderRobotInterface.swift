//
//  MoveToFolderRobotProtocol.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 23.07.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import pmtest

fileprivate struct id {
    /// Move to folder dialog identifiers
    static let addFolderButtonIdentifier = LocalString._move_to_new_folder
    static let addLabelButtonIdentifier = LocalString._label_as_new_label
    static let applyMoveToFolderButtonIdentifier = "LabelsViewController.applyButton"
    static let cancelMoveToFolderButtonIdentifier = "LabelsViewController.cancelButton"
    static func folderCellIdentifier(_ folderName: String) -> String { return "\(folderName)" }

    /// Add new folder dialog identifiers
    static let folderNameTextFieldIdentifier = "Label_Name.nameField"
    static let cancelAddFolderButtonIdentifier = "LabelEditViewController.cancelButton"
    static let applyAddFolderButtonIdentifier = "LabelEditViewController.applyButton"
    static let colorCollectionViewIdentifier = "LabelEditViewController.collectionView"
    static let doneButtonLabel = LocalString._general_done_button
    static let doneKyboardButtonIdentifier = LocalString._general_done_button.lowercased()
}

/**
 Parent class for Label and Folder dialogs in all the Mailbox Robot classes like Inbox, Sent, Trash, etc.
*/
class MoveToFolderRobotInterface: CoreElements {
    
    @discardableResult
    func clickAddFolder() -> MoveToFolderRobotInterface {
        cell(id.addFolderButtonIdentifier).tap()
        return self
    }
    
    @discardableResult
    func clickAddLabel() -> MoveToFolderRobotInterface {
        cell(id.addLabelButtonIdentifier).tap()
        return self
    }
    
    @discardableResult
    func selectFolder(_ folderName: String) -> MoveToFolderRobotInterface {
        cell(id.folderCellIdentifier(folderName)).tap()
        return self
    }
    
    @discardableResult
    func selectLabel(_ labelName: String) -> MoveToFolderRobotInterface {
        cell(id.folderCellIdentifier(labelName)).tap()
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
        textField(id.folderNameTextFieldIdentifier).tap().typeText(folderName)
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
    
    @discardableResult
    func tapDoneCreatingButton<T: CoreElements>(robot _: T.Type) -> T {
        button(id.doneButtonLabel).tap()
        return T()
    }
    
    @discardableResult
    func tapDoneSelectingFolderButton() -> InboxRobot {
        button(id.doneButtonLabel).waitForHittable().tap()
        return InboxRobot()
    }
    
    @discardableResult
    func tapDoneSelectingLabelButton() -> MessageRobot {
        button(id.doneButtonLabel).waitForHittable().tap()
        return MessageRobot()
    }
    
    func moveToExistingFolder(name: String) -> MoveToFolderRobotInterface {
        //TODO:: add implementation
        return self
    }
}
