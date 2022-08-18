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

final class LabelManagerViewController: UITableViewController {

    private enum Layout {
        static let sectionWithTitleHeight: CGFloat = 32.0
        static let sectionWithoutTitleHeight: CGFloat = 52.0
        static let cellHeight: CGFloat = 48.0
    }

    private let navBarReorderButton = SubviewFactory.navBarReorderButton
    private let navBarDoneButton = SubviewFactory.navBarDoneButton

    private let viewModel: LabelManagerViewModelProtocol
    private var dragBeginIndex: IndexPath?
    private var dragDestIndex: IndexPath?

    init(viewModel: LabelManagerViewModelProtocol) {
        self.viewModel = viewModel
        super.init(style: .plain)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        viewModel.output.setUIDelegate(self)
        viewModel.input.viewDidLoad()
    }

    private func setupUI() {
        title = viewTitle()

        navBarDoneButton.target = self
        navBarDoneButton.action = #selector(didTapDone)
        navBarReorderButton.target = self
        navBarReorderButton.action = #selector(didTapReorder)
        navigationItem.rightBarButtonItem = navBarReorderButton

        setupTableView()
    }

    private func setupTableView() {
        tableView.backgroundColor = ColorProvider.BackgroundSecondary
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.register(SwitchTableViewCell.self)
        tableView.register(
            MenuItemTableViewCell.defaultNib(),
            forCellReuseIdentifier: MenuItemTableViewCell.defaultID()
        )
        tableView.separatorStyle = .none
        tableView.rowHeight = Layout.cellHeight
    }

    @objc private func didTapReorder() {
        viewModel.input.didTapReorderBegin()
    }

    @objc private func didTapDone() {
        viewModel.input.didTapReorderEnd()
    }

    private func viewTitle() -> String {
        return viewModel.output.labelType.isFolder ? LocalString._folders : LocalString._labels
    }
}

// MARK: LabelManagerUIProtocol

extension LabelManagerViewController: LabelManagerUIProtocol {
    func reloadData() {
        hideLoadingHUD()
        tableView.reloadData()
    }

    func viewModeDidChange(mode: LabelManagerViewModel.ViewMode) {
        tableView.isEditing = mode.isReorder
        switch mode {
        case .list:
            title = viewTitle()
            navigationItem.rightBarButtonItem = navBarReorderButton
        case .reorder:
            title = LocalString._reorder
            navigationItem.rightBarButtonItem = navBarDoneButton
        }
    }

    func reload(section: Int) {
        hideLoadingHUD()
        tableView.beginUpdates()
        let indexSet = IndexSet(integer: section)
        tableView.reloadSections(indexSet, with: .fade)
        tableView.endUpdates()
    }

    func showLoadingHUD() {
        MBProgressHUD.showAdded(to: view, animated: true)
    }

    func hideLoadingHUD() {
        MBProgressHUD.hide(for: view, animated: true)
    }

    func showToast(message: String) {
        message.alertToastBottom()
    }

    func showAlertMaxItemsReached() {
        let isFolder = viewModel.output.labelType.isFolder
        let title = isFolder ? LocalString._creating_folder_not_allowed : LocalString._creating_label_not_allowed
        let message = isFolder ? LocalString._upgrade_to_create_folder : LocalString._upgrade_to_create_label
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addOKAction()
        present(alert, animated: true)
    }

    func showNoInternetConnectionToast() {
        LocalString._general_pm_offline.alertToastBottom(subtitle: LocalString._please_connect_and_retry)
    }
}

// MARK: TableView
extension LabelManagerViewController {

    // MARK: Section Header
    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.output.sections.count
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch viewModel.output.sectionType(at: section) {
        case .create, .switcher:
            return Layout.sectionWithoutTitleHeight
        case .data:
            return Layout.sectionWithTitleHeight
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard viewModel.output.sectionType(at: section).hasTitle else {
            return UIView()
        }
        let title = viewModel.output.labelType.isFolder ? LocalString._your_folders : LocalString._your_labels
        return PMHeaderView(title: title)
    }

    // MARK: Cell
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.output.numberOfRows(in: section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch viewModel.output.sectionType(at: indexPath.section) {
        case .switcher:
            return switcherCell(for: indexPath)
        case .create:
            return creationCell(for: indexPath)
        case .data:
            return dataCell(for: indexPath)
        }
    }

    private func switcherCell(for indexPath: IndexPath) -> SwitchTableViewCell {
        let identifier = SwitchTableViewCell.CellID
        guard let cell = tableView
                .dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? SwitchTableViewCell else {
            return .init()
        }
        let data = viewModel.output.switchData(at: indexPath)
        cell.configCell(
            data.title,
            bottomLine: "",
            status: data.value
        ) { [weak self] _, newStatus, feedback in
            if indexPath.row == 0 {
                self?.viewModel.input.didChangeUseFolderColors(isEnabled: newStatus)
            } else {
                self?.viewModel.input.didChangeInheritColorFromParentFolder(isEnabled: newStatus)
            }
            feedback(true)
        }
        cell.selectionStyle = .none
        cell.contentView.backgroundColor = ColorProvider.BackgroundNorm
        if tableView.isEditing {
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
        let title = viewModel.output.labelType.isFolder ? LocalString._new_folder: LocalString._new_label
        instance.textLabel?.attributedText = title.apply(style: .DefaultHint)
        instance.imageView?.image = IconProvider.plus
        instance.contentView.backgroundColor = ColorProvider.BackgroundNorm

        if tableView.isEditing {
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

        let data = viewModel.output.data(at: indexPath)
        let useFolderColor = viewModel.output.useFolderColor
        cell.config(by: data, showArrow: false, useFillIcon: useFolderColor, delegate: nil)

        let color = viewModel.output.getFolderColor(label: data)
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
        viewModel.input.didSelectItem(at: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: Editing related
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        switch viewModel.output.sectionType(at: indexPath.section) {
        case .create, .switcher:
            return false
        case .data:
            return true
        }
    }

    override func tableView(
        _ tableView: UITableView,
        editingStyleForRowAt indexPath: IndexPath
    ) -> UITableViewCell.EditingStyle {
        return .none
    }

    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func tableView(
        _ tableView: UITableView,
        moveRowAt sourceIndexPath: IndexPath,
        to destinationIndexPath: IndexPath
    ) {
        viewModel.input.move(sourceIndex: sourceIndexPath, to: destinationIndexPath)
    }

    override func tableView(
        _ tableView: UITableView,
        targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
        toProposedIndexPath proposedDestinationIndexPath: IndexPath
    ) -> IndexPath {
        guard let sectionIndex = viewModel.output.sections.firstIndex(of: .data),
              sourceIndexPath.section == sectionIndex,
              proposedDestinationIndexPath.section == sectionIndex
        else {
            return sourceIndexPath
        }

        let sourceLabel = viewModel.output.data(at: sourceIndexPath)
        let targetLabel = viewModel.output.data(at: proposedDestinationIndexPath)

        let wantToMoveUp = sourceIndexPath.row > proposedDestinationIndexPath.row
        let sourceLevel = sourceLabel.indentationLevel
        let targetLevel = targetLabel.indentationLevel

        if sourceLevel == targetLevel {
            return handleSameLevelMove(
                sourceLabel: sourceLabel,
                targetLabel: targetLabel,
                proposedDestinationIndexPath: proposedDestinationIndexPath,
                sourceIndexPath: sourceIndexPath
            )
        } else if sourceLevel < targetLevel {
            var parentID = targetLabel.parentID
            if parentID == sourceLabel.location.labelID {
                return sourceIndexPath
            }
            while let parentLabel = viewModel.output.queryLabel(id: parentID?.rawValue) {
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

                guard var row = viewModel.output.getRowOfLabelID(parentLabel.location.labelID) else {
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

    private func handleSameLevelMove(
        sourceLabel: MenuLabel,
        targetLabel: MenuLabel,
        proposedDestinationIndexPath: IndexPath,
        sourceIndexPath: IndexPath
    ) -> IndexPath {
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

extension LabelManagerViewController {

    private enum SubviewFactory {
        static var navBarButtonTextAttr: [NSAttributedString.Key : Any] = {
            var attr = FontManager.HeadlineSmall
            attr[.foregroundColor] = ColorProvider.InteractionNorm
            return attr
        }()

        static var navBarReorderButton: UIBarButtonItem = {
            let button = UIBarButtonItem(title: LocalString._reorder, style: .plain, target: nil, action: nil)
            button.setTitleTextAttributes(navBarButtonTextAttr, for: .normal)
            return button
        }()

        static var navBarDoneButton: UIBarButtonItem = {
            let button = UIBarButtonItem(title: LocalString._general_done_button, style: .plain, target: nil, action: nil)
            button.setTitleTextAttributes(navBarButtonTextAttr, for: .normal)
            return button
        }()
    }
}

extension LabelManagerViewModel.SectionType {

    var hasTitle: Bool {
        switch self {
        case .create, .switcher:
            return false
        case .data:
            return true
        }
    }
}
