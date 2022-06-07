//
//  LabelManagerViewController.swift
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

import MBProgressHUD
import ProtonCore_UIFoundations
import UIKit

protocol LabelManagerUIProtocol: AnyObject {
    func showLoadingHUD()
    func hideLoadingHUD()
    func reloadData()
    func reload(section: Int)
    func showToast(message: String)
}

final class LabelManagerViewController: UITableViewController {
    private var viewModel: LabelManagerProtocol!
    private var coordinator: LabelManagerCoordinator!
    private var isEditingModeOn = false
    private var dragBeginIndex: IndexPath?
    private var dragDestIndex: IndexPath?

    class func instance(needNavigation: Bool = false) -> LabelManagerViewController {
        let instance = Self(style: .plain)
        if needNavigation {
            _ = UINavigationController(rootViewController: instance)
        }
        return instance
    }

    func set(viewModel: LabelManagerProtocol, coordinator: LabelManagerCoordinator) {
        self.viewModel = viewModel
        self.coordinator = coordinator
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(self.viewModel != nil, "Please use set(viewModel:coordinator:) to setting initialize view model")
        assert(self.coordinator != nil, "Please use set(viewModel:coordinator:) to setting initialize coordinator")
        self.setupNavigationBar()
        self.setupTable()
        self.viewModel.viewDidLoad()
    }
}

extension LabelManagerViewController {
    private func setupNavigationBar() {
        self.title = self.viewModel.viewTitle
        self.setupReorderBtn()
    }

    private func setupReorderBtn() {
        let reorder = UIBarButtonItem(title: LocalString._reorder,
                                      style: .plain,
                                      target: self,
                                      action: #selector(self.enableReorderMode))
        var attr = FontManager.HeadlineSmall
        attr[.foregroundColor] = ColorProvider.InteractionNorm
        reorder.setTitleTextAttributes(attr, for: .normal)
        self.navigationItem.rightBarButtonItem = reorder
    }

    private func setupDoneBtn() {
        let done = UIBarButtonItem(title: LocalString._general_done_button,
                                   style: .plain,
                                   target: self,
                                   action: #selector(self.disableReorderMode))
        var attr = FontManager.HeadlineSmall
        attr[.foregroundColor] = ColorProvider.InteractionNorm
        done.setTitleTextAttributes(attr, for: .normal)
        self.navigationItem.rightBarButtonItem = done
    }

    private func setupTable() {
        self.tableView.backgroundColor = ColorProvider.BackgroundSecondary
        self.tableView.tableFooterView = UIView(frame: .zero)
        self.tableView.register(SwitchTableViewCell.self)
        self.tableView.register(MenuItemTableViewCell.defaultNib(),
                                forCellReuseIdentifier: MenuItemTableViewCell.defaultID())
        self.tableView.separatorStyle = .none
        self.tableView.rowHeight = 48
//        self.tableView.dragDelegate = self
//        self.tableView.dropDelegate = self
    }

    @objc
    private func enableReorderMode() {
        guard self.viewModel.hasNetworking else {
            LocalString._general_pm_offline.alertToastBottom(subtitle: LocalString._please_connect_and_retry)
            return
        }
        self.updateEditingMode(isOn: true)
//        self.tableView.dragInteractionEnabled = true
        self.setupDoneBtn()
    }

    @objc
    private func disableReorderMode() {
        self.updateEditingMode(isOn: false)
//        self.tableView.dragInteractionEnabled = false
        self.setupReorderBtn()
    }

    private func updateEditingMode(isOn: Bool) {
        self.tableView.isEditing = isOn
        self.isEditingModeOn = isOn
        self.viewModel.enableReorder(isReorder: isOn)
        self.title = isOn ? LocalString._reorder: self.viewModel.viewTitle
    }
}

// MARK: LabelManagerUIProtocol
extension LabelManagerViewController: LabelManagerUIProtocol {
    func reloadData() {
        self.hideLoadingHUD()
        self.tableView.reloadData()
    }

    func reload(section: Int) {
        self.hideLoadingHUD()
        self.tableView.beginUpdates()
        let set = IndexSet(integer: section)
        self.tableView.reloadSections(set, with: .fade)
        self.tableView.endUpdates()
    }

    func showLoadingHUD() {
        MBProgressHUD.showAdded(to: self.view, animated: true)
    }

    func hideLoadingHUD() {
        MBProgressHUD.hide(for: self.view, animated: true)
    }

    func showToast(message: String) {
        message.alertToastBottom()
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addOKAction()
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: TableView
extension LabelManagerViewController {

    // MARK: Section Header
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.section.count
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return self.viewModel.getHeight(of: section)
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if self.viewModel.getHeight(of: section) == self.viewModel.HEIGHTWITHOUTTITLE {
            let view = UIView()
            return view
        }

        let title = self.viewModel.type == .folder ? LocalString._your_folders: LocalString._your_labels
        let view = PMHeaderView(title: title,
                                fontSize: 15,
                                titleColor: ColorProvider.TextWeak,
                                background: ColorProvider.BackgroundSecondary)
        return view
    }

    // MARK: Cell
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.numberOfRows(in: section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch self.viewModel.section[indexPath.section] {
        case .switcher:
            return self.switcherCell(for: indexPath)
        case .create:
            return self.creationCell(for: indexPath)
        case .data:
            return self.dataCell(for: indexPath)
        }
    }

    private func switcherCell(for indexPath: IndexPath) -> SwitchTableViewCell {
        let identifier = SwitchTableViewCell.CellID
        guard let cell = tableView
                .dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? SwitchTableViewCell else {
            return .init()
        }
        let data = self.viewModel.switcherData(of: indexPath)
        cell.configCell(data.title,
                        bottomLine: "",
                        status: data.value) { [weak self] _, newStatus, feedback in
            if indexPath.row == 0 {
                self?.viewModel.enableUseFolderColor(isEnable: newStatus)
            } else {
                self?.viewModel.enableInherit(isEnable: newStatus)
            }
            feedback(true)
        }
        cell.selectionStyle = .none
        cell.contentView.backgroundColor = ColorProvider.BackgroundNorm
        if self.tableView.isEditing {
            cell.switchView.isEnabled = false
            cell.switchView.onTintColor = ColorProvider.IconDisabled
            cell.topLineLabel.textColor = ColorProvider.TextDisabled
        }
        cell.addSeparator(padding: 0)
        return cell
    }

    private func creationCell(for indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "defaultCellWithIcon")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "defaultCellWithIcon")
        }
        cell?.addSeparator(padding: 0)
        guard let instance = cell else { return .init() }
        instance.textLabel?.attributedText = self.viewModel.createTitle.apply(style: .DefaultHint)
        instance.imageView?.image = IconProvider.plus
        instance.contentView.backgroundColor = ColorProvider.BackgroundNorm

        if self.tableView.isEditing {
            instance.imageView?.tintColor = ColorProvider.IconDisabled
            instance.textLabel?.textColor = ColorProvider.TextDisabled
        } else {
            instance.imageView?.tintColor = ColorProvider.IconWeak
            instance.textLabel?.textColor = ColorProvider.TextWeak
        }

        return instance
    }

    private func dataCell(for indexPath: IndexPath) -> MenuItemTableViewCell {
        let identifier = MenuItemTableViewCell.defaultID()
        guard let cell = tableView
                .dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? MenuItemTableViewCell else {
            return .init()
        }

        let data = self.viewModel.data(of: indexPath)
        let useFolderColor = self.viewModel.useFolderColor
        cell.config(by: data, showArrow: false, useFillIcon: useFolderColor, delegate: nil)

        let color = self.viewModel.getFolderColor(label: data)
        cell.update(iconColor: color)
        cell.update(textColor: ColorProvider.TextNorm)
        cell.update(attribure: FontManager.Default.lineBreakMode())
        cell.backgroundColor = ColorProvider.BackgroundNorm
        cell.selectionStyle = .none
        cell.accessoryType = .disclosureIndicator
        cell.addSeparator(padding: 0)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !self.tableView.isEditing else { return }

        self.tableView.deselectRow(at: indexPath, animated: true)
        let section = indexPath.section
        switch self.viewModel.section[section] {
        case .switcher:
            return
        case .create:
            guard self.viewModel.allowToCreate() else {
                self.showAlert(title: self.viewModel.createLimitationTitle,
                               message: self.viewModel.createLimitationMessage)
                return
            }
            self.coordinator.goToEditing(label: nil)
        case .data:
            let label = self.viewModel.data(of: indexPath)
            self.coordinator.goToEditing(label: label)
        }
    }

    // MARK: Editing related
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        switch self.viewModel.section[indexPath.section] {
        case .create, .switcher:
            return false
        case .data:
            return true
        }
    }

    override func tableView(_ tableView: UITableView,
                            editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func tableView(_ tableView: UITableView,
                            moveRowAt sourceIndexPath: IndexPath,
                            to destinationIndexPath: IndexPath) {
        self.viewModel.move(sourceIndex: sourceIndexPath, to: destinationIndexPath)
    }

    override func tableView(_ tableView: UITableView,
                            targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
                            toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {

        guard let sectionIndex = self.viewModel.section.firstIndex(of: .data),
              sourceIndexPath.section == sectionIndex,
              proposedDestinationIndexPath.section == sectionIndex else {
            return sourceIndexPath
        }

        let sourceLabel = self.viewModel.data(of: sourceIndexPath)
        let targetLabel = self.viewModel.data(of: proposedDestinationIndexPath)

        let wantToMoveUp = sourceIndexPath.row > proposedDestinationIndexPath.row
        let sourceLevel = sourceLabel.indentationLevel
        let targetLevel = targetLabel.indentationLevel

        if sourceLevel == targetLevel {
            return self.handleSameLevelMove(sourceLabel: sourceLabel,
                                            targetLabel: targetLabel,
                                            proposedDestinationIndexPath: proposedDestinationIndexPath,
                                            sourceIndexPath: sourceIndexPath)
        } else if sourceLevel < targetLevel {
            var parentID = targetLabel.parentID
            if parentID == sourceLabel.location.labelID {
                return sourceIndexPath
            }
            while let parentLabel = self.viewModel.queryLabel(id: parentID?.rawValue) {
                guard parentLabel.indentationLevel == sourceLevel else {
                    parentID = parentLabel.parentID
                    continue
                }
                guard sourceLabel.parentID == parentLabel.parentID else {
                    return sourceIndexPath
                }
                if sourceLabel.location.rawLabelID == parentLabel.location.rawLabelID {
                    return sourceIndexPath
                }

                guard var row = self.viewModel.data.getRow(of: parentLabel.location.labelID) else {
                    return sourceIndexPath
                }
                if wantToMoveUp {
                    row = max(row, row - 1)
                    return IndexPath(row: row, section: proposedDestinationIndexPath.section)
                } else {
                    let childRows = [parentLabel].getNumberOfRows() - 1
                    return IndexPath(row: row + childRows, section: proposedDestinationIndexPath.section)
                }
            }
            return sourceIndexPath
        }
        return sourceIndexPath
    }

    private func handleSameLevelMove(sourceLabel: MenuLabel,
                                     targetLabel: MenuLabel,
                                     proposedDestinationIndexPath: IndexPath,
                                     sourceIndexPath: IndexPath) -> IndexPath {
        if sourceLabel.parentID == targetLabel.parentID {
            let childRows = [targetLabel].getNumberOfRows() - 1
            if childRows == 0 {
                return proposedDestinationIndexPath
            } else {
                let newRow = proposedDestinationIndexPath.row + childRows
                return IndexPath(row: newRow, section: proposedDestinationIndexPath.section)
            }
        } else {
            return sourceIndexPath
        }
    }
}

/*
We don't have enough time to improve drag & drop function
 So we use movement as our temporary solution
 We will improve this as good as web when we available
 Question: When is the free time :)
 */
/*
extension LabelManagerViewController: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView,
                   itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {

        guard self.viewModel.section[indexPath.section] == .data,
              let data = self.viewModel.data.getFolderItem(by: indexPath) else { return []
        }
        self.dragBeginIndex = indexPath
        let itemProvider = NSItemProvider(object: data.location.labelID as NSItemProviderWriting)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        return [dragItem]
//        let dragItem = UIDragItem(itemProvider: NSItemProvider(object: data))
//        return [dragItem]
    }
}

extension LabelManagerViewController: UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: MenuLabel.self)
    }

    func tableView(_ tableView: UITableView,
                   dropSessionDidUpdate session: UIDropSession,
                   withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {

        guard let dataSection = self.viewModel.section.firstIndex(of: .data),
              let indexPath = destinationIndexPath,
              let dragIndex = self.dragBeginIndex,
              indexPath.section == dataSection else {
            self.setDataCell(isHighLight: false, at: self.dragDestIndex)
            self.dragDestIndex = nil
            return .init(operation: .forbidden)
        }

        if indexPath.row == dragIndex.row {
            self.setDataCell(isHighLight: false, at: self.dragDestIndex)
            self.dragDestIndex = nil
            return .init(operation: .cancel)
        }

        let point = session.location(in: self.tableView)

        self.setDataCell(isHighLight: false, at: self.dragDestIndex)

        self.dragDestIndex = indexPath
        self.setDataCell(isHighLight: true, at: indexPath)

        let sourceItem = self.viewModel.data(of: dragIndex)
        let destItem = self.viewModel.data(of: indexPath)
        if sourceItem.contain(item: destItem) {
            // Can't drag into the child folder
            return UITableViewDropProposal(operation: .forbidden)
        }

        if destItem.canInsert(item: sourceItem) {
            return UITableViewDropProposal(operation: .copy)
        } else {
            return UITableViewDropProposal(operation: .forbidden)
        }

    }

    private func setDataCell(isHighLight: Bool, at indexPath: IndexPath?) {
        if let path = indexPath,
           let newCell = self.tableView.cellForRow(at: path) {
            newCell.setHighlighted(isHighLight, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, dropSessionDidEnd session: UIDropSession) {
        self.setDataCell(isHighLight: false, at: self.dragDestIndex)
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        guard let dragIndex = self.dragBeginIndex,
              let indexPath = self.dragDestIndex else {
            return
        }
        self.viewModel.drag(sourceIndex: dragIndex, into: indexPath)
    }
}
*/
