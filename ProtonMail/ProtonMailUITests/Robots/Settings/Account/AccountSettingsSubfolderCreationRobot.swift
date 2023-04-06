import fusion

fileprivate struct id {
    
    static let backButtonText = LocalString._parent_folder
    static let doneButtonIdentifier = "UINavigationItem.rightBarButtonItem"
    static let parentFolderSelectionTable = "LabelParentSelectViewController.tableView"
    static func folderCellIdentifier(folderName: String) -> String {
        return "MenuItemTableViewCell.\(folderName)"
    }
}

class AccountSettingsSubfolderCreationRobot: CoreElements {
    
    func selectParentFolder(_ name: String) -> AccountSettingsSubfolderCreationRobot {
        cell(id.folderCellIdentifier(folderName: name))
            .inTable(table(id.parentFolderSelectionTable))
            .tap()
        return self
    }
        
    func navigateBackToNewFolder() -> AccountSettingsLabelsAndFoldersRobot {
        button(id.backButtonText).tap()
        return AccountSettingsLabelsAndFoldersRobot()
    }
    
    func tapDoneButton() -> AccountSettingsAddFolderLabelRobot {
        button(id.doneButtonIdentifier).tap()
        return AccountSettingsAddFolderLabelRobot()
    }
}
