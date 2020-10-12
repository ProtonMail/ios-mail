//
//  LabelsAndFoldersRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 11.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

private let addFolderButtonIdentifier = "LablesViewController.addFolderButton"
private let addLabelButtonIdentifier = "LablesViewController.addLabelButton"
private let folderNameTextFieldIdentifier = "LableEditViewController.newLabelInput"
private let createButtonIdentifier = "LableEditViewController.applyButton"
private let keyboardDoneIdentifier = "Done"
private let deleteButtonIdentifier = LocalString._general_delete_action
private func labelFolderCellIdentifier(_ name: String) -> String { return "LabelTableViewCell.\(name)" }
private func labelFolderSelectButtonIdentifier(_ name: String) -> String { return "\(name).selectStatusButton" }

/**
 LabelsAndFoldersRobot class represents Labels/Folders view.
 */
class LabelsAndFoldersRobot {
    
    var verify: Verify! = nil
    init() { verify = Verify() }

    func addFolder() -> AddFolderLabelRobot {
        Element.button.tapByIdentifier(addFolderButtonIdentifier)
        return AddFolderLabelRobot()
    }
    
    func addLabel() -> AddFolderLabelRobot {
        Element.button.tapByIdentifier(addLabelButtonIdentifier)
        return AddFolderLabelRobot()
    }
    
    func deleteFolderLabel(_ name: String) -> AccountSettingsRobot {
        return selectFolderLabel(name)
            .delete()
    }
    
    private func selectFolderLabel(_ name: String) -> LabelsAndFoldersRobot {
        Element.button.tapByIdentifier(labelFolderSelectButtonIdentifier(name))
        return self
    }
    
    private func delete() -> AccountSettingsRobot {
        Element.button.tapByIdentifier(deleteButtonIdentifier)
        return AccountSettingsRobot()
    }
    
    /**
     AddFolderLabelRobot class represents  modal state with color selection and Label/Folder name text field.
     */
    class AddFolderLabelRobot {
        
        func createFolderLabel(_ name: String) -> LabelsAndFoldersRobot {
            return setFolderLabelName(name)
                .done()
                .create()
        }
        
        private func setFolderLabelName(_ name: String) -> AddFolderLabelRobot {
            Element.wait.forTextFieldWithIdentifier(folderNameTextFieldIdentifier).typeText(name)
            return self
        }
        
        private func done() -> AddFolderLabelRobot {
            Element.wait.forButtonWithIdentifier(keyboardDoneIdentifier).tap()
            return self
        }
        
        private func create() -> LabelsAndFoldersRobot {
            Element.wait.forButtonWithIdentifier(createButtonIdentifier).tap()
            return LabelsAndFoldersRobot()
        }
    }
    
    /**
     Contains all the validations that can be performed by LabelsAndFoldersRobot.
     */
    class Verify {
        
        func folderLabelCreated(_ name: String) {
            Element.assert.cellWithIdentifierExists(labelFolderCellIdentifier(name))
        }
        
        func folderLabelDeleted(_ name: String) {
            Element.assert.cellWithIdentifierDoesNotExists(labelFolderCellIdentifier(name))
        }
    }
}
