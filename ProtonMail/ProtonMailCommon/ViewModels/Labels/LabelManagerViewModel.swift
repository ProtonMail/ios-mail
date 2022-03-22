//
//  LabelManagerViewModel.swift
//  ProtonMail
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

import CoreData
import Foundation
import ProtonCore_Networking
import ProtonCore_UIFoundations

protocol LabelManagerProtocol: AnyObject {
    var data: [MenuLabel] { get }
    var type: PMLabelType { get }
    var user: UserManager { get }
    var section: [LabelManagerViewModel.SectionType] { get }
    var HEIGHTWITHOUTTITLE: CGFloat { get }
    var useFolderColor: Bool { get }
    var inheritParentFolderColor: Bool { get }
    var viewTitle: String { get }
    var createTitle: String { get }
    var hasNetworking: Bool { get }
    var createLimitationMessage: String { get }
    var createLimitationTitle: String { get }

    func set(uiDelegate: LabelManagerUIProtocol)
    func viewDidLoad()
    func getHeight(of section: Int) -> CGFloat
    func numberOfRows(in section: Int) -> Int
    func switcherData(of indexPath: IndexPath) -> (title: String, value: Bool)
    func data(of indexPath: IndexPath) -> MenuLabel
    func queryLabel(id: String?) -> MenuLabel?
    func move(sourceIndex: IndexPath, to destIndex: IndexPath)
    func drag(sourceIndex: IndexPath, into destIndex: IndexPath)
    func getFolderColor(label: MenuLabel) -> UIColor
    func allowToCreate() -> Bool
    func enableReorder(isReorder: Bool)

    func enableUseFolderColor(isEnable: Bool)
    func enableInherit(isEnable: Bool)
}

extension LabelManagerViewModel {
    enum SectionType {
        case switcher, create, data
    }
}

final class LabelManagerViewModel: NSObject {
    /// Label data after sorting out
    private(set) var data: [MenuLabel] = []
    private(set) var type: PMLabelType
    private(set) var user: UserManager
    let HEIGHTWITHTITLE: CGFloat = 52
    let HEIGHTWITHOUTTITLE: CGFloat = 32

    private var fetchedLabels: NSFetchedResultsController<NSFetchRequestResult>?
    private var rawData: [MenuLabel] = []
    private var isReorder: Bool = false
    private weak var uiDelegate: LabelManagerUIProtocol?

    init(user: UserManager, type: PMLabelType) {
        self.user = user
        self.type = type
    }
}

extension LabelManagerViewModel: LabelManagerProtocol {
    var section: [LabelManagerViewModel.SectionType] {
        if self.type == .label {
            return [.create, .data]
        } else {
            return [.switcher, .create, .data]
        }
    }

    var viewTitle: String {
        return self.type == .folder ? LocalString._folders: LocalString._labels
    }

    var createTitle: String {
        return self.type == .folder ? LocalString._new_folder: LocalString._new_label
    }

    var useFolderColor: Bool {
        return self.user.userInfo.enableFolderColor == 1
    }

    var inheritParentFolderColor: Bool {
        return self.user.userInfo.inheritParentFolderColor == 1
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

    var createLimitationTitle: String {
        switch self.type {
        case .folder:
            return LocalString._creating_folder_not_allowed
        case .label:
            return LocalString._creating_label_not_allowed
        default:
            return LocalString._general_alert_title
        }
    }

    var createLimitationMessage: String {
        switch self.type {
        case .folder:
            return LocalString._upgrade_to_create_folder
        case .label:
            return LocalString._upgrade_to_create_label
        default:
            return LocalString._general_alert_title
        }
    }

    func set(uiDelegate: LabelManagerUIProtocol) {
        self.uiDelegate = uiDelegate
    }

    func viewDidLoad() {
        self.fetchLabel()
    }

    func getHeight(of section: Int) -> CGFloat {
        switch self.section[section] {
        case .create, .switcher:
            return HEIGHTWITHOUTTITLE
        case .data:
            return HEIGHTWITHTITLE
        }
    }

    func numberOfRows(in section: Int) -> Int {
        if self.type == .label {
            switch self.section[section] {
            case .switcher:
                return 0
            case .create:
                return 1
            case .data:
                return self.data.count
            }
        } else {
            switch self.section[section] {
            case .switcher:
                return self.user.userinfo.enableFolderColor + 1
            case .create:
                return 1
            case .data:
                return self.data.getNumberOfRows()
            }
        }
    }

    func switcherData(of indexPath: IndexPath) -> (title: String, value: Bool) {
        if indexPath.row == 0 {
            let value = self.user.userinfo.enableFolderColor == 1
            return (title: LocalString._use_folder_color,
                    value: value)
        } else {
            let value = self.user.userinfo.inheritParentFolderColor == 1
            return (title: LocalString._inherit_parent_color,
                    value: value)
        }
    }

    func data(of indexPath: IndexPath) -> MenuLabel {
        if self.type == .label {
            return self.labelData(of: indexPath)
        } else {
            return self.folderData(of: indexPath)
        }
    }

    func queryLabel(id: String?) -> MenuLabel? {
        guard let labelID = id else { return nil }
        return self.rawData.first(where: { $0.location.labelID == labelID })
    }

    func move(sourceIndex: IndexPath, to destIndex: IndexPath) {

        self.uiDelegate?.showLoadingHUD()
        let sourceLabel = self.data(of: sourceIndex)
        var targetLabel = self.data(of: destIndex)

        // Make sure source and target are in the same level
        if sourceLabel.indentationLevel != targetLabel.indentationLevel {
            while let parentLabel = self.queryLabel(id: targetLabel.parentID) {
                if parentLabel.indentationLevel == sourceLabel.indentationLevel {
                    targetLabel = parentLabel
                    break
                }
            }
        }

        if sourceLabel.parentID?.isEmpty ?? true {
            guard let index = self.data.firstIndex(of: sourceLabel),
                  let targetIndex = self.data.firstIndex(of: targetLabel) else {
                self.sortoutRawData(data: self.rawData)
                return
            }
            if index == targetIndex {
                self.uiDelegate?.hideLoadingHUD()
                return
            }
            self.data.remove(at: index)
            self.data.insert(sourceLabel, at: targetIndex)

            let labelIDs = self.data.map { $0.location.labelID }
            self.orderLabel(labelIDs: labelIDs, parentID: nil)
//            self.uiDelegate?.reload(section: sectionIndex)
            return
        }

        guard let parentLabel = self.queryLabel(id: sourceLabel.parentID),
              let index = parentLabel.subLabels.firstIndex(of: sourceLabel),
              let targetIndex = parentLabel.subLabels.firstIndex(of: targetLabel) else {
            self.sortoutRawData(data: self.rawData)
            return
        }
        if index == targetIndex {
            self.uiDelegate?.hideLoadingHUD()
            return
        }

        parentLabel.subLabels.remove(at: index)
        parentLabel.subLabels.insert(sourceLabel, at: targetIndex)
        let labelIDs = parentLabel.subLabels.map { $0.location.labelID }
        self.orderLabel(labelIDs: labelIDs,
                        parentID: parentLabel.location.labelID)
    }

    /// Drag function
    /// It needs more time to improve to support movement
    /// But we don't have the time, should improve in the future
    func drag(sourceIndex: IndexPath, into destIndex: IndexPath) {
        guard let sectionIndex = self.section.firstIndex(of: .data) else {
            return
        }
        self.uiDelegate?.showLoadingHUD()

        let sourceItem = self.data(of: sourceIndex)
        let destItem = self.data(of: destIndex)

        if let parentLabel = self.queryLabel(id: sourceItem.parentID) {
            guard let index = parentLabel.subLabels.firstIndex(of: sourceItem) else {
                self.uiDelegate?.hideLoadingHUD()
                return
            }
            parentLabel.subLabels.remove(at: index)
        } else {
            guard let index = self.data.firstIndex(of: sourceItem) else {
                self.uiDelegate?.hideLoadingHUD()
                return
            }
            self.data.remove(at: index)
        }

        let diff = destItem.indentationLevel - sourceItem.indentationLevel + 1
        sourceItem.increseIndentationLevel(diff: diff)

        sourceItem.set(parentID: destItem.location.labelID)
        destItem.subLabels.append(sourceItem)
        self.uiDelegate?.reload(section: sectionIndex)
    }

    func enableUseFolderColor(isEnable: Bool) {
        self.uiDelegate?.showLoadingHUD()
        let req = EnableFolderColorRequest(isEnable: isEnable)
        self.user.apiService.exec(route: req, responseObject: MailSettingsResponse()) { [weak self] _, response in
            guard let self = self else { return }
            self.handle(mailSettingsResponse: response)
        }
    }

    func enableInherit(isEnable: Bool) {
        self.uiDelegate?.showLoadingHUD()
        let req = InheritParentFolderColorRequest(isEnable: isEnable)
        self.user.apiService.exec(route: req, responseObject: MailSettingsResponse()) { [weak self] _, response in
            guard let self = self else { return }
            self.handle(mailSettingsResponse: response)
        }
    }

    /// Get folder color, will handle inheritParentColor
    func getFolderColor(label: MenuLabel) -> UIColor {
        guard self.type == .folder else {
            if let labelColor = label.iconColor {
                return UIColor(hexColorCode: labelColor)
            } else {
                return ColorProvider.IconNorm
            }
        }

        guard self.useFolderColor else {
            return ColorProvider.IconNorm
        }
        guard self.inheritParentFolderColor else {
            if let labelColor = label.iconColor {
                return UIColor(hexColorCode: labelColor)
            } else {
                return ColorProvider.IconNorm
            }
        }

        guard let root = self.data.getRootItem(of: label),
              let rootColor = root.iconColor else {
            if let labelColor = label.iconColor {
                return UIColor(hexColorCode: labelColor)
            } else {
                return ColorProvider.IconNorm
            }
        }
        return UIColor(hexColorCode: rootColor)
    }

    func allowToCreate() -> Bool {
        guard self.user.userInfo.subscribed == 0 else { return true }
        switch self.type {
        case .folder:
            return self.rawData.count < Constants.FreePlan.maxNumberOfFolders
        case .label:
            return self.rawData.count < Constants.FreePlan.maxNumberOfLabels
        default:
            return false
        }
    }

    func enableReorder(isReorder: Bool) {
        self.isReorder = isReorder
        if isReorder {
            self.data.forEach { $0.subLabels = [] }
            self.uiDelegate?.reloadData()
        } else {
            self.fetchLabel()
        }
    }
}

extension LabelManagerViewModel {
    private func fetchLabel() {
        let service = self.user.labelService

        let fetchtype: LabelFetchType = self.type == .folder ? .folder: .label
        self.fetchedLabels = service.fetchedResultsController(fetchtype)
        self.fetchedLabels?.delegate = self
        guard let result = self.fetchedLabels else { return }
        do {
            try result.performFetch()
            let dbItems = (result.fetchedObjects as? [Label]) ?? []
            self.sortoutDBData(dbItems: dbItems)
        } catch {
        }
    }

    private func sortoutDBData(dbItems: [Label]) {
        let datas: [MenuLabel] = Array(labels: dbItems, previousRawData: [])
        self.sortoutRawData(data: datas)
    }

    private func sortoutRawData(data: [MenuLabel]) {
        data.forEach { label in
            label.subLabels = []
            label.indentationLevel = 0
        }
        self.rawData = data
        let (labelItems, folderItems) = self.rawData.sortoutData()
        if self.type == .folder {
            self.data = folderItems
        } else {
            self.data = labelItems
        }
        if isReorder {
            self.data.forEach { $0.subLabels = [] }
        }
        self.uiDelegate?.reloadData()
    }

    private func labelData(of indexPath: IndexPath) -> MenuLabel {
        if indexPath.section == 0 {
            let addLabel = MenuLabel(id: LabelLocation.addLabel.labelID,
                                     name: LocalString._labels_add_label_action,
                                     parentID: nil,
                                     path: "tmp",
                                     textColor: nil,
                                     iconColor: nil,
                                     type: 1,
                                     order: 9_999,
                                     notify: false)
            return addLabel
        }
        return self.data[indexPath.row]
    }

    private func folderData(of indexPath: IndexPath) -> MenuLabel {
        switch self.section[indexPath.section] {
        case .create:
            let addFolder = MenuLabel(id: LabelLocation.addFolder.labelID,
                                      name: LocalString._labels_add_folder_action,
                                      parentID: nil,
                                      path: "tmp",
                                      textColor: nil,
                                      iconColor: nil,
                                      type: 1,
                                      order: 9_999,
                                      notify: false)
            return addFolder
        case .data:
            guard let item = self.data.getFolderItem(by: indexPath) else {
                assert(false, "bugs")
                return MenuLabel(location: .bugs)
            }
            return item
        default:
            assert(false, "bugs")
            return MenuLabel(location: .bugs)
        }
    }

    private func handle(mailSettingsResponse: MailSettingsResponse) {
        self.uiDelegate?.hideLoadingHUD()
        if let error = mailSettingsResponse.error {
            self.uiDelegate?.showToast(message: error.localizedDescription)
            guard let index = self.section.firstIndex(of: .switcher) else {
                return
            }
            self.uiDelegate?.reload(section: index)
            return
        }
        self.user.userInfo.parse(mailSettings: mailSettingsResponse.mailSettings)
        self.user.save()
        self.uiDelegate?.reloadData()
    }

    private func orderLabel(labelIDs: [String], parentID: String?) {
        let reqType: PMLabelType = self.type == .folder ? .folder: .label
        let req = LabelOrderRequest(siblingLabelID: labelIDs, parentID: parentID, type: reqType)
        self.user.apiService.exec(route: req, responseObject: VoidResponse()) { [weak self] _, res in
            guard let self = self else { return }
            if let error = res.error {
                self.sortoutRawData(data: self.rawData)
                self.uiDelegate?.showToast(message: error.localizedDescription)
                return
            }
            self.user.labelService.fetchV4Labels().cauterize()
        }
    }
}

extension LabelManagerViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {

        let dbItems = (controller.fetchedObjects as? [Label]) ?? []
        self.sortoutDBData(dbItems: dbItems)
    }
}
