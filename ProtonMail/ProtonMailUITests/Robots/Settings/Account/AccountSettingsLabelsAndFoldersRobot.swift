//
//  LabelsAndFoldersRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 11.10.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import pmtest

fileprivate struct id {
    static let newFolderText = "New folder"
    static let newLabel = "New label"
    static let folderNameTextFieldIdentifier = "Label_Name.nameField"
    static let createButtonIdentifier = "LabelEditViewController.applyButton"
    static let closeButtonIdentifier = "LabelEditViewController.closeButton"
    static let keyboardDoneIdentifier = "Done"
    static let saveButtonLabel = LocalString._general_save_action
    static let deleteCellIdentifier = "LabelEditViewController.deleteCell"
    static let confirmDeleteButtonText = LocalString._general_delete_action
    static func labelFolderCellIdentifier(_ name: String) -> String { return "LabelTableViewCell.\(name)" }
    static func selectLabelFolderCellIdentifiert(_ name: String) -> String { return "MenuItemTableViewCell.\(name)" }
    static func editLabelFolderButtonIdentifier(_ name: String) -> String { return "MenuItemTableViewCell.\(name)" }
    static let colorCollectionViewCellIdentifier = "LabelPaletteCell.LabelColorCell"
}

/**
 LabelsAndFoldersRobot class represents Labels/Folders view.
 */
class AccountSettingsLabelsAndFoldersRobot: CoreElements {
    
    var verify = Verify()

    func addFolder() -> AddFolderLabelRobot {
        staticText(id.newFolderText).tap()
        return AddFolderLabelRobot()
    }
    
    func addLabel() -> AddFolderLabelRobot {
        staticText(id.newLabel).tap()
        return AddFolderLabelRobot()
    }
    
    func deleteFolderLabel(_ name: String) -> AccountSettingsLabelsAndFoldersRobot {
        return selectFolderLabel(name).delete().confirmDelete()
    }
    
    func editFolderLabel(_ folderName: String) -> AddFolderLabelRobot {
        cell(id.selectLabelFolderCellIdentifiert(folderName)).tap()
        return AddFolderLabelRobot()
    }
    
    func close() -> AccountSettingsRobot {
        button(id.closeButtonIdentifier).tap()
        return AccountSettingsRobot()
    }
    
    func selectFolderLabel(_ name: String) -> AddFolderLabelRobot {
        cell(id.selectLabelFolderCellIdentifiert(name))
            .firstMatch()
            .swipeUpUntilVisible()
            .waitForHittable()
            .tap()
        return AddFolderLabelRobot()
    }
    
    /**
     AddFolderLabelRobot class represents  modal state with color selection and Label/Folder name text field.
     */
    class AddFolderLabelRobot: CoreElements {
        
        func createFolderLabel(_ name: String) -> AccountSettingsLabelsAndFoldersRobot {
            return setFolderLabelName(name)
                .doneCreatingLabel()
        }
        
        private func setFolderLabelName(_ name: String) -> AddFolderLabelRobot {
            textField(id.folderNameTextFieldIdentifier).tap().typeText(name)
            return self
        }
        
        func editFolderLabelName(_ name: String) -> AddFolderLabelRobot {
            textField(id.folderNameTextFieldIdentifier).tap().clearText().typeText(name)
            return AddFolderLabelRobot()
        }
        
        func selectFolderColorByIndex(_ index: Int) -> AddFolderLabelRobot {
            image(id.colorCollectionViewCellIdentifier).byIndex(index).tap()
            return AddFolderLabelRobot()
        }
        
        func save() -> AccountSettingsLabelsAndFoldersRobot {
            button(id.saveButtonLabel).tap()
            return AccountSettingsLabelsAndFoldersRobot()
        }
        
        func doneCreatingLabel() -> AccountSettingsLabelsAndFoldersRobot {
            button(id.keyboardDoneIdentifier).tap().waitUntilGone()
            return AccountSettingsLabelsAndFoldersRobot()
        }
        
        func delete() -> AddFolderLabelRobot {
            cell(id.deleteCellIdentifier).waitForHittable().tap()
            return self
        }
        
        func confirmDelete() -> AccountSettingsLabelsAndFoldersRobot {
            button(id.confirmDeleteButtonText).tap()
            return AccountSettingsLabelsAndFoldersRobot()
        }
    }
    
    /**
     Contains all the validations that can be performed by LabelsAndFoldersRobot.
     */
    class Verify: CoreElements {
        
        func folderLabelExists(_ name: String) {
            cell(id.labelFolderCellIdentifier(name)).wait().checkExists()
        }
        
        func folderLabelDeleted(_ name: String) {
            cell(id.labelFolderCellIdentifier(name)).waitUntilGone()
        }
    }
}
