//
//  LabelsAndFoldersRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 11.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

fileprivate let addFolderButtonIdentifier = "LablesViewController.addFolderButton"
fileprivate let addLabelButtonIdentifier = "LablesViewController.addLabelButton"
fileprivate let folderNameTextFieldIdentifier = "LableEditViewController.newLabelInput"
fileprivate let createButtonIdentifier = "LableEditViewController.applyButton"
fileprivate let closeButtonIdentifier = "LableEditViewController.closeButton"
fileprivate let keyboardDoneIdentifier = "Done"
fileprivate let deleteButtonIdentifier = LocalString._general_delete_action
fileprivate func labelFolderCellIdentifier(_ name: String) -> String { return "LabelTableViewCell.\(name)" }
fileprivate func selectLabelFolderButtonIdentifier(_ name: String) -> String { return "\(name).selectStatusButton" }
fileprivate func editLabelFolderButtonIdentifier(_ name: String) -> String { return "\(name).editButton" }
fileprivate let colorCollectionViewIdentifier = "LableEditViewController.collectionView"

/**
 LabelsAndFoldersRobot class represents Labels/Folders view.
 */
class AccountSettingsLabelsAndFoldersRobot {
    
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
        selectFolderLabel(name)
            .delete()
    }
    
    func editFolderLabel(_ folderName: String) -> AddFolderLabelRobot {
        Element.wait.forButtonWithIdentifier(editLabelFolderButtonIdentifier(folderName), file: #file, line: #line).tap()
        return AddFolderLabelRobot()
    }
    
    func close() -> AccountSettingsRobot {
        Element.wait.forButtonWithIdentifier(closeButtonIdentifier, file: #file, line: #line).tap()
        return AccountSettingsRobot()
    }
    
    private func selectFolderLabel(_ name: String) -> AccountSettingsLabelsAndFoldersRobot {
        Element.button.tapByIdentifier(selectLabelFolderButtonIdentifier(name))
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
        
        func createFolderLabel(_ name: String) -> AccountSettingsLabelsAndFoldersRobot {
            return setFolderLabelName(name)
                .done()
                .create()
        }
        
        private func setFolderLabelName(_ name: String) -> AddFolderLabelRobot {
            Element.wait.forTextFieldWithIdentifier(folderNameTextFieldIdentifier, file: #file, line: #line).typeText(name)
            return self
        }
        
        func editFolderLabelName(_ name: String) -> AddFolderLabelRobot {
            Element.wait.forTextFieldWithIdentifier(folderNameTextFieldIdentifier, file: #file, line: #line)
                .clear()
                .typeText(name)
            return AddFolderLabelRobot()
        }
        
        func selectFolderColorByIndex(_ index: Int) -> AddFolderLabelRobot {
            Element.wait.forCollectionViewWithIdentifier(colorCollectionViewIdentifier, file: #file, line: #line).clickCellByIndex(index)
            return AddFolderLabelRobot()
        }
        
        func done() -> AddFolderLabelRobot {
            Element.wait.forButtonWithIdentifier(keyboardDoneIdentifier, file: #file, line: #line).tap()
            return self
        }
        
        func create() -> AccountSettingsLabelsAndFoldersRobot {
            Element.wait.forButtonWithIdentifier(createButtonIdentifier, file: #file, line: #line).tap()
            return AccountSettingsLabelsAndFoldersRobot()
        }
    }
    
    /**
     Contains all the validations that can be performed by LabelsAndFoldersRobot.
     */
    class Verify {
        
        func folderLabelExists(_ name: String) {
            Element.assert.cellWithIdentifierExists(labelFolderCellIdentifier(name))
        }
        
        func folderLabelDeleted(_ name: String) {
            Element.assert.cellWithIdentifierDoesNotExists(labelFolderCellIdentifier(name))
        }
    }
}
