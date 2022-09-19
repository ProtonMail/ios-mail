//
//  LabelEditViewController.swift
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

final class LabelEditViewController: UITableViewController {
    private var navBarDoneButton: UIBarButtonItem = SubviewFactory.navBarButton

    private var viewModel: LabelEditViewModelProtocol

    init(viewModel: LabelEditViewModelProtocol) {
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
    }
}

extension LabelEditViewController {

    private func setupUI() {
        view.backgroundColor = ColorProvider.BackgroundSecondary
        setupNavigationBar()
        setupTableView()
        emptyBackButtonTitleForNextView()
    }

    private func setupNavigationBar() {
        setupNavBarTitle()
        setupNavBarButtons()
        navigationController?.navigationBar.barTintColor = ColorProvider.BackgroundNorm
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = false
    }

    private func setupNavBarTitle() {
        let localisedTitle: String
        if viewModel.output.labelType.isFolder {
            localisedTitle = viewModel.output.editMode.isCreationMode
            ? LocalString._new_folder
            : LocalString._edit_folder
        } else {
            localisedTitle = viewModel.output.editMode.isCreationMode
            ? LocalString._new_label
            : LocalString._edit_label
        }
        title = localisedTitle
    }

    private func setupNavBarButtons() {
        let discardButton = IconProvider.cross.toUIBarButtonItem(
            target: self,
            action: #selector(self.clickDiscardButton),
            style: .plain,
            tintColor: ColorProvider.IconNorm,
            squareSize: 24,
            backgroundColor: nil,
            backgroundSquareSize: nil,
            isRound: false
        )
        navigationItem.leftBarButtonItem = discardButton

        let isCreationMode = viewModel.output.editMode.isCreationMode
        navBarDoneButton.title = isCreationMode ? LocalString._general_done_button : LocalString._general_save_action
        navBarDoneButton.target = self
        navBarDoneButton.action = #selector(didTapDoneButton)
        navigationItem.rightBarButtonItem = navBarDoneButton
        checkDoneButtonStatus()
    }

    private func setupTableView() {
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.backgroundColor = ColorProvider.BackgroundSecondary
        tableView.register(LabelPaletteCell.defaultNib(), forCellReuseIdentifier: LabelPaletteCell.defaultID())
        tableView.register(SwitchTableViewCell.self)
        tableView.register(LabelNameCell.defaultNib(), forCellReuseIdentifier: LabelNameCell.defaultID())
        tableView.register(SettingsGeneralCell.self)
        tableView.register(LabelInfoCell.defaultNib(), forCellReuseIdentifier: LabelInfoCell.defaultID())

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100

        guard let keyWindow = UIApplication.shared.windows.first else {
            return
        }
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyWindow.safeAreaInsets.bottom, right: 0)
    }
}

// MARK: Functions
extension LabelEditViewController {
    @objc
    private func didTapDoneButton() {
        view.endEditing(true)
        viewModel.input.saveChanges()
    }

    @objc
    private func clickDiscardButton() {
        view.endEditing(true)

        guard viewModel.output.hasChanged else {
            dismiss(animated: true, completion: nil)
            viewModel.input.didCloseView()
            return
        }

        let title = "\(LocalString._discard_changes)?"
        let alert = UIAlertController(
            title: title,
            message: LocalString._discard_change_message,
            preferredStyle: .alert
        )
        let discard = UIAlertAction(title: LocalString._general_discard, style: .destructive) { _ in
            self.viewModel.input.didDiscardChanges()
        }
        let cancelAction = UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil)
        [discard, cancelAction].forEach(alert.addAction)
        navigationController?.present(alert, animated: true, completion: nil)
    }
}

extension LabelEditViewController: LabelEditUIProtocol {
    func updateParentFolderName() {
        guard let section = viewModel.output.sections.firstIndex(of: .folderOptions) else {
            return
        }
        let path = IndexPath(row: 0, section: section)
        guard let cell = self.tableView.cellForRow(at: path) as? SettingsGeneralCell else {
            return
        }
        cell.configure(right: viewModel.output.parentLabelName ?? LocalString._general_none)
    }

    func checkDoneButtonStatus() {
        navBarDoneButton.isEnabled = !viewModel.output.shouldDisableDoneButton
    }

    func updatePaletteSection(index: Int) {
        self.tableView.beginUpdates()
        let section = IndexSet(integer: index)
        self.tableView.reloadSections(section, with: .automatic)
        self.tableView.endUpdates()
    }

    func showLoadingHUD() {
        MBProgressHUD.showAdded(to: self.view, animated: true)
    }

    func hideLoadingHUD() {
        MBProgressHUD.hide(for: self.view, animated: true)
    }

    func showAlert(message: String) {
        message.alertToastBottom()
    }

    private func deleteTitle() -> String {
        return viewModel.output.labelType.isFolder ? LocalString._delete_folder : LocalString._delete_label
    }

    func showAlertDeleteItem() {
        let message = viewModel.output.labelType.isFolder
        ? LocalString._delete_folder_message
        : LocalString._delete_label_message

        let alert = UIAlertController(title: deleteTitle(), message: message, preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: LocalString._general_delete_action, style: .destructive) { _ in
            self.viewModel.input.didConfirmDeleteItem()
        }

        let cancelAction = UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil)
        [deleteAction, cancelAction].forEach(alert.addAction)
        self.navigationController?.present(alert, animated: true, completion: nil)
    }

    func showNoInternetConnectionToast() {
        LocalString._general_pm_offline.alertToastBottom(subtitle: LocalString._please_connect_and_retry)
    }
}

extension LabelEditViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.output.sections.count
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch viewModel.output.sections[section] {
        case .palette, .colorInherited:
            return PMHeaderView(title: LocalString._select_colour)
        default:
            return PMHeaderView(title: "")
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return viewModel.output.sections[section].headerHeight
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        // Group style has extra 20 px of footer
        // UI trick, 0 has no effect
        return 0.01
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.output.sections[section].numberOfRows
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch viewModel.output.sections[indexPath.section] {
        case .name:
            return self.setupNameCell(indexPath: indexPath)
        case .folderOptions:
            if indexPath.row == 0 {
                return self.setupParentFolder(indexPath: indexPath)
            } else {
                return self.setupNoficationCell(indexPath: indexPath)
            }
        case .colorInherited:
            return self.setupLabelInfoCell(indexPath: indexPath)
        case .palette:
            return self.setupPaletteCell(indexPath: indexPath)
        case .delete:
            return self.setupDeleteCell()
        }
    }

    private func setupNameCell(indexPath: IndexPath) -> LabelNameCell {
        let identifier = LabelNameCell.defaultID()
        guard let cell = self.tableView
                .dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? LabelNameCell else {
            return .init()
        }
        cell.config(name: viewModel.output.labelProperties.name, type: viewModel.output.labelType, delegate: self)
        cell.addSeparator(padding: 0)
        return cell
    }

    private func setupParentFolder(indexPath: IndexPath) -> SettingsGeneralCell {
        let identifier = SettingsGeneralCell.CellID
        guard let cell = self.tableView
                .dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? SettingsGeneralCell else {
            return .init()
        }

        cell.configure(left: LocalString._parent_folder)
        cell.configure(right: viewModel.output.parentLabelName ?? LocalString._general_none)
        cell.addSeparator(padding: 0)
        cell.contentView.backgroundColor = ColorProvider.BackgroundNorm
        return cell
    }

    private func setupNoficationCell(indexPath: IndexPath) -> SwitchTableViewCell {
        let identifier = SwitchTableViewCell.CellID
        guard let cell = self.tableView
                .dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? SwitchTableViewCell else {
            return .init()
        }

        cell.configCell(
            LocalString._general_notifications,
            isOn: viewModel.output.labelProperties.notify
        ) { newStatus, feedback in
            self.viewModel.input.updateProperty(notify: newStatus)
            feedback(true)
        }
        cell.selectionStyle = .none
        cell.addSeparator(padding: 0)
        cell.contentView.backgroundColor = ColorProvider.BackgroundNorm
        return cell
    }

    private func setupPaletteCell(indexPath: IndexPath) -> LabelPaletteCell {
        let identifier = LabelPaletteCell.defaultID()
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: identifier,
            for: indexPath
        ) as? LabelPaletteCell else {
            return .init()
        }
        cell.selectionStyle = .none
        cell.config(
            colors: ColorManager.forLabel,
            intenseColors: ColorManager.intenseColors,
            selected: viewModel.output.labelProperties.iconColor,
            type: viewModel.output.labelType,
            delegate: self
        )
        cell.addSeparator(padding: 0)
        return cell
    }

    private func setupLabelInfoCell(indexPath: IndexPath) -> LabelInfoCell {
        let identifier = LabelInfoCell.defaultID()
        guard let cell = self.tableView
                .dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? LabelInfoCell else {
            return .init()
        }
        let info = LocalString._color_inherited_from_parent_folder
        let icon = IconProvider.infoCircle
        cell.config(info: info, icon: icon, cellHeight: 88)
        cell.addSeparator(padding: 0)
        return cell
    }

    private func setupDeleteCell() -> UITableViewCell {
        var cell = self.tableView.dequeueReusableCell(withIdentifier: "deleteCell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "deleteCell")
        }

        guard let instance = cell else { return .init() }

        var attr = FontManager.Default
        attr[.foregroundColor] = ColorProvider.NotificationError as UIColor
        instance.textLabel?.attributedText = deleteTitle().apply(style: attr)
        instance.textLabel?.textAlignment = .center
        instance.addSeparator(padding: 0)
        instance.contentView.backgroundColor = ColorProvider.BackgroundNorm
        instance.accessibilityIdentifier = "LabelEditViewController.deleteCell"
        return instance
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.input.didSelectItem(at: indexPath)
    }
}

extension LabelEditViewController: LabelPaletteCellDelegate, LabelNameDelegate {

    func nameChanged(name: String) {
        viewModel.input.updateProperty(name: name)
    }

    func selectColor(hex: String) {
        viewModel.input.updateProperty(iconColor: hex)
    }
}

private extension LabelEditViewController {

    private enum SubviewFactory {
        static var navBarButton: UIBarButtonItem = {
            let btn = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            btn.setTitleTextAttributes(enabledNavBarButtonAttr, for: .normal)
            btn.setTitleTextAttributes(disabledNavBarButtonAttr, for: .disabled)
            return btn
        }()

        static var enabledNavBarButtonAttr: [NSAttributedString.Key : Any] {
            var attr = FontManager.HeadlineSmall
            attr[.foregroundColor] = ColorProvider.InteractionNorm as UIColor
            return attr
        }

        static var disabledNavBarButtonAttr: [NSAttributedString.Key : Any] {
            var disableAttr = FontManager.HeadlineSmall
            disableAttr[.foregroundColor] = ColorProvider.InteractionNormDisabled as UIColor
            return disableAttr
        }
    }
}

private extension LabelEditViewSection {

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
