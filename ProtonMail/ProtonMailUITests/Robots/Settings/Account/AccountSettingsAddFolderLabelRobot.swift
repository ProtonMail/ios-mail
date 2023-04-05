// Copyright (c) 2023 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import fusion

fileprivate struct id {
    static let keyboardDoneIdentifier = "Done"
    static let folderNameTextFieldIdentifier = "Label_Name.nameField"
    static let colorCollectionViewCellIdentifier = "LabelPaletteCell.LabelColorCell"
    static let saveButtonLabel = LocalString._general_save_action
    static let deleteCellIdentifier = "LabelEditViewController.deleteCell"
    static let confirmDeleteButtonText = LocalString._general_delete_action
}

/**
 AddFolderLabelRobot class represents  modal state with color selection and Label/Folder name text field.
 */
class AccountSettingsAddFolderLabelRobot: CoreElements {
    
    func createFolderLabel(_ name: String) -> AccountSettingsLabelsAndFoldersRobot {
        return setFolderLabelName(name)
            .doneCreatingLabel()
    }
    
    private func setFolderLabelName(_ name: String) -> Self {
        textField(id.folderNameTextFieldIdentifier).tap().typeText(name)
        return self
    }
    
    func editFolderLabelName(_ name: String) -> Self {
        textField(id.folderNameTextFieldIdentifier).tap().clearText().typeText(name)
        return self
    }
    
    func selectParentFolderOption() -> AccountSettingsSubfolderCreationRobot {
        cell("SettingsGeneralCell.Parent_folder").tap()
        return AccountSettingsSubfolderCreationRobot()
    }
    
    func selectFolderColorByIndex(_ index: Int) -> Self {
        image(id.colorCollectionViewCellIdentifier).byIndex(index).tap()
        return self
    }
    
    func save() -> AccountSettingsLabelsAndFoldersRobot {
        button(id.saveButtonLabel).tap()
        return AccountSettingsLabelsAndFoldersRobot()
    }
    
    func doneCreatingLabel() -> AccountSettingsLabelsAndFoldersRobot {
        button(id.keyboardDoneIdentifier).tap().waitUntilGone()
        return AccountSettingsLabelsAndFoldersRobot()
    }
    
    func delete() -> Self {
        cell(id.deleteCellIdentifier).waitForHittable().tap()
        return self
    }
    
    func confirmDelete() -> AccountSettingsLabelsAndFoldersRobot {
        button(id.confirmDeleteButtonText).tap()
        return AccountSettingsLabelsAndFoldersRobot()
    }
}
