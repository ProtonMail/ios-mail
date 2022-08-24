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

import UIKit

protocol LabelManagerViewModelProtocol: AnyObject {
    var input: LabelManagerViewModelInput { get }
    var output: LabelManagerViewModelOutput { get }
}

protocol LabelManagerViewModelInput: AnyObject {
    func viewDidLoad()

    func didTapReorderBegin()
    func didTapReorderEnd()
    func didSelectItem(at index: IndexPath)
    func didChangeUseFolderColors(isEnabled: Bool)
    func didChangeInheritColorFromParentFolder(isEnabled: Bool)

    func move(sourceIndex: IndexPath, to destIndex: IndexPath)
}

protocol LabelManagerViewModelOutput: AnyObject {
    func setUIDelegate(_ delegate: LabelManagerUIProtocol)

    var sections: [LabelManagerViewModel.SectionType] { get }
    var labelType: PMLabelType { get }
    var useFolderColor: Bool { get }

    func numberOfRows(in section: Int) -> Int
    func switchData(at indexPath: IndexPath) -> (title: String, value: Bool)
    func data(at indexPath: IndexPath) -> MenuLabel
    func queryLabel(id: String?) -> MenuLabel?

    func sectionType(at section: Int) -> LabelManagerViewModel.SectionType
    func getFolderColor(label: MenuLabel) -> UIColor
    func getRowOfLabelID(_ labelID: LabelID) -> Int?
}

protocol LabelManagerUIProtocol: AnyObject {
    func viewModeDidChange(mode: LabelManagerViewModel.ViewMode)
    func showLoadingHUD()
    func hideLoadingHUD()
    func reloadData()
    func reload(section: Int)
    func showToast(message: String)
    func showAlertMaxItemsReached()
    func showNoInternetConnectionToast()
}
