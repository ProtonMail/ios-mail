// Copyright (c) 2022 Proton AG
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

import Foundation

protocol LabelEditViewModelProtocol: AnyObject {
    var input: LabelEditViewModelInput { get }
    var output: LabelEditViewModelOutput { get }
}

protocol LabelEditViewModelInput: AnyObject {
    func didSelectItem(at indexPath: IndexPath)

    func updateProperty(name: String)
    func updateProperty(iconColor: String)
    func updateProperty(notify: Bool)
    func saveChanges()

    func didConfirmDeleteItem()
    func didDiscardChanges()
    func didCloseView()
}

protocol LabelEditViewModelOutput: AnyObject {
    func setUIDelegate(_ delegate: LabelEditUIProtocol)

    var sections: [LabelEditViewSection] { get }
    var editMode: LabelEditMode { get }
    var labelType: PMLabelType { get }
    var parentLabelName: String? { get }
    var labelProperties: LabelEditProperties { get }

    var shouldDisableDoneButton: Bool { get }
    var hasChanged: Bool { get }
}

protocol LabelEditUIProtocol: AnyObject {
    func updateParentFolderName()
    func checkDoneButtonStatus()
    func updatePaletteSection(index: Int)
    func showLoadingHUD()
    func hideLoadingHUD()
    func showAlert(message: String)
    func showAlertDeleteItem()
    func showNoInternetConnectionToast()
}
