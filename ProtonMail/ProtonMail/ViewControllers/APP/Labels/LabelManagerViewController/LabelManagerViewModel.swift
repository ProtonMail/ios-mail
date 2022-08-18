//
//  LabelManagerViewModel.swift
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

import class ProtonCore_DataModel.UserInfo
import ProtonCore_Networking
import ProtonCore_Services
import ProtonCore_UIFoundations

final class LabelManagerViewModel: LabelManagerViewModelProtocol {
    var input: LabelManagerViewModelInput { self }
    var output: LabelManagerViewModelOutput { self }

    private let router: LabelManagerRouterProtocol
    private weak var uiDelegate: LabelManagerUIProtocol?

    private(set) var data: [MenuLabel] = []
    let labelType: PMLabelType
    private let dependencies: Dependencies
    private var isFetching = false

    private var rawData: [MenuLabel] = []

    private var viewMode: ViewMode = .list {
        didSet {
            uiDelegate?.viewModeDidChange(mode: viewMode)
        }
    }

    private var hasNetworking: Bool {
        guard let reachability = Reachability.forInternetConnection() else {
            return false
        }
        return reachability.currentReachabilityStatus() != .NotReachable
    }

    init(router: LabelManagerRouterProtocol, type: PMLabelType, dependencies: Dependencies) {
        self.router = router
        self.labelType = type
        self.dependencies = dependencies
    }
}

// MARK: Input

extension LabelManagerViewModel: LabelManagerViewModelInput {

    func viewDidLoad() {
        fetchLabels()
    }

    func didTapReorderBegin() {
        guard hasNetworking else {
            uiDelegate?.showNoInternetConnectionToast()
            return
        }
        viewMode = .reorder
        data.forEach { $0.subLabels = [] }
        uiDelegate?.reloadData()
    }

    func didTapReorderEnd() {
        viewMode = .list
        fetchLabels()
    }

    func didSelectItem(at index: IndexPath) {
        guard !viewMode.isReorder else { return }
        switch sections[index.section] {
        case .switcher:
            return
        case .create:
            guard allowToCreate() else {
                uiDelegate?.showAlertMaxItemsReached()
                return
            }
            createNewLabel()
        case .data:
            let label = data(at: index)
            editLabel(label)
        }
    }

    func didChangeUseFolderColors(isEnabled: Bool) {
        uiDelegate?.showLoadingHUD()
        let req = EnableFolderColorRequest(isEnable: isEnabled)
        dependencies.apiService.exec(route: req, responseObject: MailSettingsResponse()) { [weak self] _, response in
            guard let self = self else { return }
            self.handle(mailSettingsResponse: response)
        }
    }

    func didChangeInheritColorFromParentFolder(isEnabled: Bool) {
        uiDelegate?.showLoadingHUD()
        let req = InheritParentFolderColorRequest(isEnable: isEnabled)
        dependencies.apiService.exec(route: req, responseObject: MailSettingsResponse()) { [weak self] _, response in
            guard let self = self else { return }
            self.handle(mailSettingsResponse: response)
        }
    }

    func move(sourceIndex: IndexPath, to destIndex: IndexPath) {
        uiDelegate?.showLoadingHUD()
        let sourceLabel = data(at: sourceIndex)
        var targetLabel = data(at: destIndex)

        // Make sure source and target are in the same level
        if sourceLabel.indentationLevel != targetLabel.indentationLevel {
            while let parentLabel = queryLabel(id: targetLabel.parentID?.rawValue) {
                if parentLabel.indentationLevel == sourceLabel.indentationLevel {
                    targetLabel = parentLabel
                    break
                }
            }
        }

        if sourceLabel.parentID?.rawValue.isEmpty ?? true {
            guard let index = data.firstIndex(of: sourceLabel),
                  let targetIndex = data.firstIndex(of: targetLabel)
            else {
                sortOutRawData(labels: rawData)
                return
            }
            if index == targetIndex {
                uiDelegate?.hideLoadingHUD()
                return
            }
            data.remove(at: index)
            data.insert(sourceLabel, at: targetIndex)

            let labelIDs = data.map { $0.location.rawLabelID }
            orderLabel(labelIDs: labelIDs, parentID: nil)
            return
        }

        guard let parentLabel = queryLabel(id: sourceLabel.parentID?.rawValue),
              let index = parentLabel.subLabels.firstIndex(of: sourceLabel),
              let targetIndex = parentLabel.subLabels.firstIndex(of: targetLabel)
        else {
            sortOutRawData(labels: rawData)
            return
        }
        if index == targetIndex {
            uiDelegate?.hideLoadingHUD()
            return
        }

        parentLabel.subLabels.remove(at: index)
        parentLabel.subLabels.insert(sourceLabel, at: targetIndex)
        let labelIDs = parentLabel.subLabels.map { $0.location.rawLabelID }
        orderLabel(labelIDs: labelIDs, parentID: parentLabel.location.rawLabelID)
    }
}

// MARK: Output

extension LabelManagerViewModel: LabelManagerViewModelOutput {

    var sections: [LabelManagerViewModel.SectionType] {
        return labelType.isFolder
        ? [.switcher, .create, .data]
        : [.create, .data]
    }

    var useFolderColor: Bool {
        dependencies.userInfo.enableFolderColor == 1
    }

    func setUIDelegate(_ delegate: LabelManagerUIProtocol) {
        uiDelegate = delegate
    }

    func numberOfRows(in section: Int) -> Int {
        if self.labelType == .label {
            switch sections[section] {
            case .switcher:
                return 0
            case .create:
                return 1
            case .data:
                return data.count
            }
        } else {
            switch self.sections[section] {
            case .switcher:
                return dependencies.userInfo.enableFolderColor + 1
            case .create:
                return 1
            case .data:
                return data.getNumberOfRows()
            }
        }
    }

    func switchData(at indexPath: IndexPath) -> (title: String, value: Bool) {
        if indexPath.row == 0 {
            let value = dependencies.userInfo.enableFolderColor == 1
            return (title: LocalString._use_folder_color,
                    value: value)
        } else {
            let value = dependencies.userInfo.inheritParentFolderColor == 1
            return (title: LocalString._inherit_parent_color,
                    value: value)
        }
    }

    func data(at indexPath: IndexPath) -> MenuLabel {
        return labelType.isFolder
        ? folderData(at: indexPath)
        : labelData(at: indexPath)
    }

    func queryLabel(id: String?) -> MenuLabel? {
        guard let labelID = id else { return nil }
        return rawData.first(where: { $0.location.rawLabelID == labelID })
    }

    func sectionType(at section: Int) -> LabelManagerViewModel.SectionType {
        return sections[section]
    }

    func getFolderColor(label: MenuLabel) -> UIColor {
        guard labelType.isFolder else {
            if let labelColor = label.iconColor {
                return UIColor(hexColorCode: labelColor)
            } else {
                return ColorProvider.IconNorm
            }
        }

        guard useFolderColor else {
            return ColorProvider.IconNorm
        }
        guard dependencies.userInfo.inheritParentFolderColor == 1 else {
            if let labelColor = label.iconColor {
                return UIColor(hexColorCode: labelColor)
            } else {
                return ColorProvider.IconNorm
            }
        }

        guard let root = data.getRootItem(of: label),
              let rootColor = root.iconColor else {
            if let labelColor = label.iconColor {
                return UIColor(hexColorCode: labelColor)
            } else {
                return ColorProvider.IconNorm
            }
        }
        return UIColor(hexColorCode: rootColor)
    }

    func getRowOfLabelID(_ labelID: LabelID) -> Int? {
        return data.getRow(of: labelID)
    }
}

// MARK: Private methods

extension LabelManagerViewModel {

    private func allowToCreate() -> Bool {
        guard dependencies.userInfo.subscribed == 0 else { return true }
        switch labelType {
        case .folder:
            return rawData.count < Constants.FreePlan.maxNumberOfFolders
        case .label:
            return rawData.count < Constants.FreePlan.maxNumberOfLabels
        default:
            return false
        }
    }

    private func fetchLabels() {
        dependencies.labelPublisher.delegate = self
        dependencies.labelPublisher.fetchLabels(labelType: labelType.isFolder ? .folder : .label)
    }

    private func sortOutRawData(labels: [MenuLabel]) {
        labels.forEach { label in
            label.subLabels = []
            label.indentationLevel = 0
        }
        rawData = labels
        let (labelItems, folderItems) = rawData.sortoutData()
        data = labelType.isFolder ? folderItems : labelItems
        if viewMode.isReorder {
            data.forEach { $0.subLabels = [] }
        }
        uiDelegate?.reloadData()
    }

    private func labelData(at indexPath: IndexPath) -> MenuLabel {
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

    private func folderData(at indexPath: IndexPath) -> MenuLabel {
        switch self.sections[indexPath.section] {
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
        uiDelegate?.hideLoadingHUD()
        if let error = mailSettingsResponse.error {
            uiDelegate?.showToast(message: error.localizedDescription)
            guard let index = self.sections.firstIndex(of: .switcher) else {
                return
            }
            uiDelegate?.reload(section: index)
            return
        }
        dependencies.userInfo.parse(mailSettings: mailSettingsResponse.mailSettings)
        dependencies.userManagerSaveAction.save()
        uiDelegate?.reloadData()
    }

    private func orderLabel(labelIDs: [String], parentID: String?) {
        let reqType: PMLabelType = self.labelType == .folder ? .folder: .label
        let req = LabelOrderRequest(siblingLabelID: labelIDs, parentID: parentID, type: reqType)
        dependencies.apiService.exec(route: req, responseObject: VoidResponse()) { [weak self] _, res in
            guard let self = self else { return }
            if let error = res.error {
                self.sortOutRawData(labels: self.rawData)
                self.uiDelegate?.showToast(message: error.localizedDescription)
                return
            }
            self.isFetching = true
            _ = self.dependencies.labelService.fetchV4Labels().done { [weak self] _ in
                self?.isFetching = false
            }
        }
    }

    private func createNewLabel() {
        router.navigateToLabelEdit(
            editMode: .creation,
            labels: data,
            type: labelType,
            userInfo: dependencies.userInfo,
            labelService: dependencies.labelService
        )
    }

    private func editLabel(_ label: MenuLabel) {
        router.navigateToLabelEdit(
            editMode: .edition(label: label),
            labels: data,
            type: labelType,
            userInfo: dependencies.userInfo,
            labelService: dependencies.labelService
        )
    }
}

extension LabelManagerViewModel: LabelListenerProtocol {

    func receivedLabels(labels: [LabelEntity]) {
        if isFetching { return }
        sortOutRawData(labels: labels.map(\.toMenuLabel))
    }
}

extension LabelManagerViewModel {

    enum SectionType {
        case switcher, create, data
    }

    enum ViewMode {
        case list
        case reorder

        var isReorder: Bool {
            self == .reorder
        }
    }
}

extension LabelManagerViewModel {

    struct Dependencies {
        let userInfo: UserInfo
        let apiService: APIService
        let labelService: LabelsDataService
        let labelPublisher: LabelPublisherProtocol
        let userManagerSaveAction: UserManagerSaveAction

        init(
            userInfo: UserInfo,
            apiService: APIService,
            labelService: LabelsDataService,
            labelPublisher: LabelPublisherProtocol,
            userManagerSaveAction: UserManagerSaveAction
        ) {
            self.userInfo = userInfo
            self.apiService = apiService
            self.labelService = labelService
            self.labelPublisher = labelPublisher
            self.userManagerSaveAction = userManagerSaveAction
        }

        init(userManager: UserManager) {
            self.userInfo = userManager.userInfo
            self.apiService = userManager.apiService
            self.labelService = userManager.labelService
            self.labelPublisher = labelService.makePublisher()
            self.userManagerSaveAction = userManager
        }
    }
}

extension PMLabelType {

    var isFolder: Bool {
        return self == .folder
    }
}
