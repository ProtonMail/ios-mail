//
//  LabelEditViewModel.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import CoreData
import Foundation


protocol LabelEditVMProtocol: AnyObject {
    var section: [LabelEditViewModel.EditSection] { get }
    var colors: [String] { get }
    var type: PMLabelType { get }
    var label: MenuLabel? { get }
    var labels: [MenuLabel] { get }
    var name: String { get }
    var iconColor: String { get }
    var viewTitle: String { get }
    var parentID: String { get }
    var networkingAlertTitle: String { get }
    var notify: Bool { get }
    var deleteMessage: String { get }
    var deleteTitle: String { get }
    var parentLabelName: String { get }
    var hasChanged: Bool { get }
    var user: UserManager { get }
    var rightBarItemTitle: String { get }
    var shouldDisableDoneButton: Bool { get }
    var hasNetworking: Bool { get }
    var doesNameDuplicate: Bool { get }

    func set(uiDelegate: LabelEditUIProtocol)
    func update(name: String)
    func update(iconColor: String)
    func update(parentID: String)
    func update(notify: Bool)
    func save()
    func delete()
}

extension LabelEditViewModel {
    enum EditSection {
        case name
        case folderOptions
        case palette
        case colorInherited
        case delete

        var headerHeight: CGFloat {
            switch self {
            case .name:
                return 16
            case .folderOptions:
                return 16
            case .palette:
                return 52
            case .colorInherited:
                return 52
            case .delete:
                return 24
            }
        }

        var numberOfRows: Int {
            switch self {
            case .name:
                return 1
            case .folderOptions:
                return 2
            case .palette:
                return 1
            case .colorInherited:
                return 1
            case .delete:
                return 1
            }
        }
    }
}

final class LabelEditViewModel {
    let colors: [String] = ColorManager.forLabel
    let type: PMLabelType
    let labels: [MenuLabel]
    let label: MenuLabel?
    let user: UserManager
    private(set) var iconColor: String {
        didSet {
            self.uiDelegate?.checkDoneButtonStatus()
        }
    }
    private(set) var section: [EditSection] = []
    private(set) var name: String {
        didSet {
            self.uiDelegate?.checkDoneButtonStatus()
        }
    }
    private(set) var notify: Bool {
        didSet {
            self.uiDelegate?.checkDoneButtonStatus()
        }
    }
    private(set) var parentID: String {
        didSet {
            self.uiDelegate?.checkDoneButtonStatus()
        }
    }
    private weak var uiDelegate: LabelEditUIProtocol?

    /// - Parameters:
    ///   - user: current user
    ///   - label: Editing label data, `nil` when creation mode
    ///   - type: Labels or Folders
    ///   - labels: The sortout label data
    init(user: UserManager,
         label: MenuLabel?,
         type: PMLabelType,
         labels: [MenuLabel]) {
        self.user = user
        self.type = type
        self.name = label?.name ?? ""
        self.parentID = label?.parentID ?? ""
        self.iconColor = label?.iconColor ?? ColorManager.forLabel[0]
        self.notify = label?.notify ?? true
        self.label = label
        self.labels = labels

        self.setupSection()
    }
}

extension LabelEditViewModel: LabelEditVMProtocol {

    var viewTitle: String {
        switch self.type {
        case .folder:
            return self.label == nil ? LocalString._new_folder: LocalString._edit_folder
        case .label:
            return self.label == nil ? LocalString._new_label: LocalString._edit_label
        default:
            return ""
        }
    }

    var rightBarItemTitle: String {
        return self.label == nil ? LocalString._general_done_button: LocalString._general_save_action
    }

    var deleteTitle: String {
        switch self.type {
        case .folder:
            return LocalString._delete_folder
        case .label:
            return LocalString._delete_label
        default:
            return ""
        }
    }

    var deleteMessage: String {
        switch self.type {
        case .folder:
            return LocalString._delete_folder_message
        case .label:
            return LocalString._delete_label_message
        default:
            return ""
        }
    }

    var parentLabelName: String {
        guard let parentLabel = self.labels.getLabel(of: self.parentID) else {
            return LocalString._general_none
        }
        return parentLabel.name
    }

    var hasChanged: Bool {
        guard let label = self.label else {
            let nameChanged = !self.name.isEmpty
            let colorChanged = self.iconColor != self.colors[0]
            let parentChanged = !self.parentID.isEmpty
            let notifyChanged = !self.notify
            return nameChanged || colorChanged || parentChanged || notifyChanged
        }
        if self.name != label.name ||
            self.iconColor != label.iconColor ||
            self.parentID != (label.parentID ?? "") ||
            self.notify != label.notify {
            return true
        }

        return false
    }

    var shouldDisableDoneButton: Bool {
        if self.name.isEmpty {
            return true
        }

        if self.label != nil && !self.hasChanged {
            return true
        }
        return false
    }

    var hasNetworking: Bool {
        guard let reachability = Reachability.forInternetConnection() else {
            return false
        }
        if reachability.currentReachabilityStatus() == .NotReachable {
            return false
        }
        return true
    }

    var networkingAlertTitle: String {
        switch self.type {
        case .folder:
            if self.label != nil {
                return LocalString._editing_folder_not_allowed
            } else {
                return LocalString._creating_folder_not_allowed
            }
        case .label:
            if self.label != nil {
                return LocalString._editing_label_not_allowed
            } else {
                return LocalString._creating_label_not_allowed
            }
        default:
            return LocalString._general_alert_title
        }
    }

    /// Does name duplicated in the selected parent folder?
    var doesNameDuplicate: Bool {
        guard let parent = self.labels.getLabel(of: self.parentID) else {
            return false
        }
        if let label = self.label,
           label.parentID == parent.location.labelID {
            return false
        }
        return parent.subLabels.map { $0.name }.contains(self.name)
    }

    func set(uiDelegate: LabelEditUIProtocol) {
        self.uiDelegate = uiDelegate
    }

    func update(name: String) {
        self.name = name
    }

    func update(iconColor: String) {
        self.iconColor = iconColor
    }

    func update(parentID: String) {
        self.parentID = parentID
        self.uiDelegate?.updateParentFolderName()
        guard self.user.userInfo.inheritParentFolderColor == 1 else {
            return
        }

        if parentID.isEmpty {
            if let index = self.section.firstIndex(of: .colorInherited) {
                self.section.remove(at: index)
                self.section.insert(.palette, at: index)
                self.uiDelegate?.updatePaletteSection(index: index)
            }
        } else {
            if let index = self.section.firstIndex(of: .palette) {
                self.section.remove(at: index)
                self.section.insert(.colorInherited, at: index)
                self.uiDelegate?.updatePaletteSection(index: index)
            }
        }
    }

    func update(notify: Bool) {
        self.notify = notify
    }

    func save() {
        if let label = self.label {
            self.updateLabel(label: label)
        } else {
            self.createLabel()
        }
    }

    func delete() {
        guard let label = self.label,
              let dbLabel = self.user.labelService.label(by: label.location.labelID) else { return }
        self.uiDelegate?.showLoadingHUD()
        
        let subFolders: [NSManagedObjectID] = label.flattenSubFolders()
            .compactMap { self.user.labelService.label(by: $0.location.labelID)?.objectID }

        self.user.labelService.deleteLabel(dbLabel, subLabelIDs: subFolders) {
            [weak self] in
            guard let self = self else { return }
            self.uiDelegate?.hideLoadingHUD()
            self.uiDelegate?.dismiss()
        }
    }
}

extension LabelEditViewModel {
    private func setupSection() {
        defer {
            if self.label != nil {
                if let index = self.section.firstIndex(where: { $0 == .palette || $0 == .colorInherited}) {
                    self.section.insert(.delete, at: index)
                } else {
                    self.section.append(.delete)
                }
            }
        }
        
        if self.type == .folder {
            self.section = [.name, .folderOptions]

            let isInherit = self.user.userinfo.inheritParentFolderColor
            let enableFolderColor = self.user.userinfo.enableFolderColor
            
            guard enableFolderColor == 1 else { return }
            if isInherit == 1 {
                let item: EditSection = self.parentID.isEmpty ? .palette: .colorInherited
                self.section.append(item)
            } else {
                self.section.append(.palette)
            }
        } else {
            self.section = [.name, .palette]
        }
    }

    private func updateLabel(label: MenuLabel) {
        guard let dbLabel = self.user.labelService.label(by: label.location.labelID) else { return }

        self.uiDelegate?.showLoadingHUD()
        self.user.labelService.updateLabel(dbLabel,
                                           name: self.name,
                                           color: self.iconColor,
                                           parentID: self.parentID,
                                           notify: self.notify) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.uiDelegate?.hideLoadingHUD()
                self.uiDelegate?.showAlert(message: error.localizedDescription)
                return
            }
            _ = self.user.labelService.fetchV4Labels().done { [weak self] _ in
                self?.uiDelegate?.hideLoadingHUD()
                self?.uiDelegate?.dismiss()
            }
        }
    }

    private func createLabel() {
        self.uiDelegate?.showLoadingHUD()
        self.user.labelService.createNewLabel(name: self.name,
                                              color: self.iconColor,
                                              type: self.type,
                                              parentID: self.parentID,
                                              notify: self.notify) { [weak self] _, error in
            guard let self = self else { return }
            if let error = error {
                self.uiDelegate?.hideLoadingHUD()
                self.uiDelegate?.showAlert(message: error.localizedDescription)
                return
            }
            _ = self.user.labelService.fetchV4Labels().done { [weak self] _ in
                self?.uiDelegate?.hideLoadingHUD()
                self?.uiDelegate?.dismiss()
            }
        }
    }
}
