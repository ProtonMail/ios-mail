//
//  LabelEditViewModel.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit
import ProtonCore_DataModel

final class LabelEditViewModel: LabelEditViewModelProtocol {
    var input: LabelEditViewModelInput { self }
    var output: LabelEditViewModelOutput { self }

    private let router: LabelEditRouterProtocol
    private weak var uiDelegate: LabelEditUIProtocol?

    let editMode: LabelEditMode
    let labelType: PMLabelType
    private var editingProperties: LabelEditProperties {
        didSet {
            uiDelegate?.checkDoneButtonStatus()
        }
    }
    private let labels: [MenuLabel]
    private var editSections: [LabelEditViewSection] = []

    private let dependencies: Dependencies

    init(
        router: LabelEditRouterProtocol,
        editMode: LabelEditMode,
        type: PMLabelType,
        labels: [MenuLabel],
        dependencies: Dependencies
    ) {
        self.router = router
        self.editMode = editMode
        self.labelType = type
        self.labels = labels
        self.editingProperties = LabelEditProperties(
            name: editMode.label?.name ?? "",
            iconColor: editMode.label?.iconColor ?? ColorManager.forLabel[0],
            parentID: editMode.label?.parentID,
            notify: editMode.label?.notify ?? true
        )
        self.dependencies = dependencies
        self.setupSection()
    }
}

extension LabelEditViewModel {

    private func setupSection() {
        defer {
            if editMode.label != nil {
                if let index = editSections.firstIndex(where: { $0 == .palette || $0 == .colorInherited}) {
                    editSections.insert(.delete, at: index)
                } else {
                    editSections.append(.delete)
                }
            }
        }

        if labelType.isFolder {
            editSections = [.name, .folderOptions]

            let isInherit = dependencies.userInfo.inheritParentFolderColor
            let enableFolderColor = dependencies.userInfo.enableFolderColor

            guard enableFolderColor == 1 else { return }
            if isInherit == 1 {
                let id = editingProperties.parentID?.rawValue ?? ""
                let item: LabelEditViewSection = id.isEmpty == true ? .palette: .colorInherited
                editSections.append(item)
            } else {
                editSections.append(.palette)
            }
        } else {
            editSections = [.name, .palette]
        }
    }

    private func updateLabel(label: MenuLabel) {
        guard let dbLabel = dependencies.labelService.label(by: label.location.labelID) else { return }

        uiDelegate?.showLoadingHUD()
        dependencies.labelService.updateLabel(
            LabelEntity(label: dbLabel),
            name: editingProperties.name,
            color: editingProperties.iconColor,
            parentID: editingProperties.parentID,
            notify: editingProperties.notify
        ) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.uiDelegate?.hideLoadingHUD()
                self.uiDelegate?.showAlert(message: error.localizedDescription)
                return
            }
            self.dependencies.labelService.fetchV4Labels { [weak self] _ in
                DispatchQueue.main.async {
                    self?.uiDelegate?.hideLoadingHUD()
                    self?.router.closeView()
                }
            }
        }
    }

    private func createLabel() {
        uiDelegate?.showLoadingHUD()
        dependencies.labelService.createNewLabel(
            name: editingProperties.name,
            color: editingProperties.iconColor,
            type: labelType,
            parentID: editingProperties.parentID,
            notify: editingProperties.notify
        ) { [weak self] _, error in
            guard let self = self else { return }
            if let error = error {
                self.uiDelegate?.hideLoadingHUD()
                self.uiDelegate?.showAlert(message: error.localizedDescription)
                return
            }
            self.dependencies.labelService.fetchV4Labels { [weak self] _ in
                DispatchQueue.main.async {
                    self?.uiDelegate?.hideLoadingHUD()
                    self?.router.closeView()
                }
            }
        }
    }

    private func updateProperty(parentID: LabelID) {
        editingProperties.parentID = parentID
        uiDelegate?.updateParentFolderName()
        guard dependencies.userInfo.inheritParentFolderColor == 1 else {
            return
        }

        if parentID.rawValue.isEmpty == true {
            if let index = editSections.firstIndex(of: .colorInherited) {
                editSections.remove(at: index)
                editSections.insert(.palette, at: index)
                uiDelegate?.updatePaletteSection(index: index)
            }
        } else {
            if let index = editSections.firstIndex(of: .palette) {
                editSections.remove(at: index)
                editSections.insert(.colorInherited, at: index)
                uiDelegate?.updatePaletteSection(index: index)
            }
        }
    }

    private var hasNetworking: Bool {
        guard let reachability = Reachability.forInternetConnection() else {
            return false
        }
        return reachability.currentReachabilityStatus() != .NotReachable
    }
}

extension LabelEditViewModel: LabelEditViewModelInput {

    func didSelectItem(at indexPath: IndexPath) {
        switch editSections[indexPath.section] {
        case .folderOptions:
            let isParentFolderSelected = indexPath.row == 0
            guard isParentFolderSelected else { return }
            router.goToParentSelect(
                label: editMode.label,
                labels: labels,
                parentID: editingProperties.parentID?.rawValue ?? "",
                isInheritParentColorEnabled: dependencies.userInfo.inheritParentFolderColor == 1,
                isFolderColorEnabled: dependencies.userInfo.enableFolderColor == 1,
                labelParentSelectDelegate: self
            )
        case .delete:
            uiDelegate?.showAlertDeleteItem()
        case .name, .palette, .colorInherited:
            return
        }
    }

    func updateProperty(name: String) {
        editingProperties.name = name
    }

    func updateProperty(iconColor: String) {
        editingProperties.iconColor = iconColor
    }

    func updateProperty(notify: Bool) {
        editingProperties.notify = notify
    }

    func saveChanges() {
        guard hasNetworking else {
            uiDelegate?.showNoInternetConnectionToast()
            return
        }

        if let label = editMode.label {
            updateLabel(label: label)
        } else {
            createLabel()
        }
    }

    func didConfirmDeleteItem() {
        guard hasNetworking else {
            uiDelegate?.showNoInternetConnectionToast()
            return
        }
        guard let label = editMode.label, let dbLabel = dependencies.labelService.label(by: label.location.labelID) else {
            return
        }
        uiDelegate?.showLoadingHUD()

        let subFolders = label.flattenSubFolders()
            .compactMap { dependencies.labelService.label(by: $0.location.labelID) }
            .compactMap(LabelEntity.init)

        dependencies.labelService.deleteLabel(LabelEntity(label: dbLabel), subLabels: subFolders) { [weak self] in
            guard let self = self else { return }
            self.uiDelegate?.hideLoadingHUD()
            self.router.closeView()
        }
    }

    func didDiscardChanges() {
        router.closeView()
    }

    func didCloseView() {
        router.closeView()
    }
}

extension LabelEditViewModel: LabelEditViewModelOutput {

    func setUIDelegate(_ delegate: LabelEditUIProtocol) {
        uiDelegate = delegate
    }

    var sections: [LabelEditViewSection] {
        editSections
    }

    var parentLabelName: String? {
        guard let parentID = editingProperties.parentID else { return nil }
        return labels.getLabel(of: parentID)?.name
    }

    var labelProperties: LabelEditProperties {
        editingProperties
    }

    var shouldDisableDoneButton: Bool {
        if editingProperties.name.isEmpty {
            return true
        }
        if editMode.label != nil && !hasChanged {
            return true
        }
        return false
    }

    var hasChanged: Bool {
        switch editMode {
        case .creation:
            let nameChanged = !editingProperties.name.isEmpty
            let colorChanged = editingProperties.iconColor != ColorManager.forLabel[0]
            let parentChanged = editingProperties.parentID?.rawValue.isEmpty == false
            let notifyChanged = !editingProperties.notify
            return nameChanged || colorChanged || parentChanged || notifyChanged
        case .edition(let label):
            let hasPropertyBeenEdited = editingProperties.name != label.name
            || editingProperties.iconColor != label.iconColor
            || editingProperties.parentID != label.parentID
            || editingProperties.notify != label.notify
            return hasPropertyBeenEdited
        }
    }
}

extension LabelEditViewModel: LabelParentSelectDelegate {

    func select(parentID: String) {
        updateProperty(parentID: LabelID(parentID))
    }
}

extension LabelEditViewModel {

    struct Dependencies {
        let userInfo: UserInfo
        let labelService: LabelsDataService

        init(userInfo: UserInfo, labelService: LabelsDataService) {
            self.userInfo = userInfo
            self.labelService = labelService
        }

        init(userManager: UserManager) {
            self.userInfo = userManager.userInfo
            self.labelService = userManager.labelService
        }
    }
}

enum LabelEditMode {
    case creation
    case edition(label: MenuLabel)

    var isCreationMode: Bool {
        switch self {
        case .creation: return true
        case .edition: return false
        }
    }

    var label: MenuLabel? {
        switch self {
        case .creation: return nil
        case .edition(let label): return label
        }
    }
}

struct LabelEditProperties {
    var name: String
    var iconColor: String
    var parentID: LabelID?
    var notify: Bool
}

enum LabelEditViewSection {
    case name
    case folderOptions
    case palette
    case colorInherited
    case delete
}
