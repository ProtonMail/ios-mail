//
//  LabelEditViewController.swift
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

import MBProgressHUD
import PMUIFoundations
import UIKit

protocol LabelEditUIProtocol: class {
    func updateParentFolderName()
    func checkDoneButtonStatus()
    func updatePaletteSection(index: Int)
    func showLoadingHUD()
    func hideLoadingHUD()
    func showAlert(message: String)
    func dismiss()
}

final class NEWLabelEditViewController: ProtonMailViewController {
    @IBOutlet private var tableView: UITableView!
    private var doneBtn: UIBarButtonItem!
    private var coordinator: LabelEditCoordinator!
    private var viewModel: LabelEditVMProtocol!

    class func instance() -> NEWLabelEditViewController {
        let board = UIStoryboard.Storyboard.inbox.storyboard
        let identifier = "NEWLabelEditViewController"
        guard let instance = board
                .instantiateViewController(withIdentifier: identifier) as? NEWLabelEditViewController else {
            return .init()
        }
        if #available(iOS 13.0, *) {
            instance.isModalInPresentation = true
        }
        _ = UINavigationController(rootViewController: instance)
        return instance
    }

    func set(viewModel: LabelEditVMProtocol, coordinator: LabelEditCoordinator) {
        self.viewModel = viewModel
        self.coordinator = coordinator
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(self.viewModel != nil, "Please use set(viewModel:) to initialize")
        self.setupViews()
        self.emptyBackButtonTitleForNextView()
    }

}

// MARK: UI related
extension NEWLabelEditViewController {
    private func setupViews() {
        self.view.backgroundColor = UIColorManager.BackgroundSecondary
        self.setupNavigationBar()
        self.setupTableView()
    }

    private func setupNavigationBar() {
        self.title = self.viewModel.viewTitle

        self.setupDoneButton()
        let discardBtn = Asset.actionSheetClose.image
            .toUIBarButtonItem(target: self,
                               action: #selector(self.clickDiscardButton),
                               style: .plain,
                               tintColor: UIColorManager.IconNorm,
                               squareSize: 24,
                               backgroundColor: nil,
                               backgroundSquareSize: nil,
                               isRound: false)
        self.navigationItem.leftBarButtonItem = discardBtn

        self.navigationController?.navigationBar.barTintColor = UIColorManager.BackgroundNorm
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = false
    }

    private func setupDoneButton() {
        self.doneBtn = UIBarButtonItem(title: self.viewModel.rightBarItemTitle,
                                       style: .plain,
                                       target: self,
                                       action: #selector(self.clickDoneButton))

        var attr = FontManager.HeadlineSmall
        attr[.foregroundColor] = UIColorManager.InteractionNorm
        self.doneBtn.setTitleTextAttributes(attr, for: .normal)

        var disableAttr = FontManager.HeadlineSmall
        disableAttr[.foregroundColor] = UIColorManager.InteractionNormDisabled
        self.doneBtn.setTitleTextAttributes(disableAttr, for: .disabled)

        self.navigationItem.rightBarButtonItem = self.doneBtn
        self.checkDoneButtonStatus()
    }

    private func setupTableView() {
        self.tableView.tableFooterView = UIView(frame: .zero)
        self.tableView.backgroundColor = UIColorManager.BackgroundSecondary
        self.tableView.register(LabelPaletteCell.defaultNib(), forCellReuseIdentifier: LabelPaletteCell.defaultID())
        self.tableView.register(SwitchTableViewCell.self)
        self.tableView.register(LabelNameCell.defaultNib(), forCellReuseIdentifier: LabelNameCell.defaultID())
        self.tableView.register(SettingsGeneralCell.self)
        self.tableView.register(LabelInfoCell.defaultNib(), forCellReuseIdentifier: LabelInfoCell.defaultID())

        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 100

        guard let keyWindow = UIApplication.shared.windows.first else {
            return
        }

        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyWindow.safeAreaInsets.bottom, right: 0)
    }
}

// MARK: Functions
extension NEWLabelEditViewController {
    @objc
    private func clickDoneButton() {
        self.view.endEditing(true)

        guard self.viewModel.hasNetworking else {
            let title = self.viewModel.networkingAlertTitle
            let message = LocalString._please_connect_and_retry
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addOKAction()
            self.present(alert, animated: true, completion: nil)
            return
        }

        guard !self.viewModel.doesNameDuplicate else {
            LocalString._folder_name_duplicated_message.alertToast()
            return
        }

        self.viewModel.save()
    }

    @objc
    private func clickDiscardButton() {
        self.view.endEditing(true)

        guard self.viewModel.hasChanged else {
            self.dismiss(animated: true, completion: nil)
            return
        }

        let title = "\(LocalString._discard_changes)?"
        let alert = UIAlertController(title: title,
                                      message: LocalString._discard_change_message,
                                      preferredStyle: .alert)
        let discard = UIAlertAction(title: LocalString._general_discard, style: .destructive) { _ in
            self.dismiss(animated: true, completion: nil)
        }
        let cancelAction = UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil)
        [discard, cancelAction].forEach(alert.addAction)
        self.navigationController?.present(alert, animated: true, completion: nil)
    }

    private func clickDeleteButton() {
        guard self.viewModel.hasNetworking else {
            let title = self.viewModel.networkingAlertTitle
            let message = LocalString._please_connect_and_retry
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addOKAction()
            self.present(alert, animated: true, completion: nil)
            return
        }

        let title = "\(self.viewModel.deleteTitle)?"
        let alert = UIAlertController(title: title, message: self.viewModel.deleteMessage, preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: LocalString._general_delete_action, style: .default) { _ in
            self.deleteLabel()
        }

        let cancelAction = UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil)
        [deleteAction, cancelAction].forEach(alert.addAction)
        self.navigationController?.present(alert, animated: true, completion: nil)
    }

    private func showParentFolderSheet() {
        self.coordinator.goToParentSelect()
    }

    private func deleteLabel() {
        self.viewModel.delete()
    }
}

// MARK: LabelEditUIProtocol
extension NEWLabelEditViewController: LabelEditUIProtocol {
    func updateParentFolderName() {
        guard let section = self.viewModel.section.firstIndex(of: .folderOptions) else {
            return
        }
        let path = IndexPath(row: 0, section: section)
        guard let cell = self.tableView.cellForRow(at: path) as? SettingsGeneralCell else {
            return
        }
        cell.configure(right: self.viewModel.parentLabelName)
    }

    func checkDoneButtonStatus() {
        self.doneBtn.isEnabled = !self.viewModel.shouldDisableDoneButton
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

    func dismiss() {
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: TableView
extension NEWLabelEditViewController: UITableViewDelegate, UITableViewDataSource {
    // MARK: Section header
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.section.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch self.viewModel.section[section] {
        case .palette, .colorInherited:
            return PMHeaderView(title: LocalString._select_colour)
        default:
            return PMHeaderView(title: "")
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return self.viewModel.section[section].headerHeight
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        // Group style has extra 20 px of footer
        // UI trick, 0 has no effect
        return 0.01
    }

    // MARK: Cells
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.section[section].numberOfRows
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch self.viewModel.section[indexPath.section] {
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
        cell.config(name: self.viewModel.name, type: self.viewModel.type, delegate: self)
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
        cell.configure(right: self.viewModel.parentLabelName)
        cell.addSeparator(padding: 0)
        cell.contentView.backgroundColor = UIColorManager.BackgroundNorm
        return cell
    }

    private func setupNoficationCell(indexPath: IndexPath) -> SwitchTableViewCell {
        let identifier = SwitchTableViewCell.CellID
        guard let cell = self.tableView
                .dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? SwitchTableViewCell else {
            return .init()
        }

        cell.configCell(LocalString._general_notifications,
                        bottomLine: "",
                        status: self.viewModel.notify) { _, newStatus, feedback in
            self.viewModel.update(notify: newStatus)
            feedback(true)
        }
        cell.selectionStyle = .none
        cell.addSeparator(padding: 0)
        cell.contentView.backgroundColor = UIColorManager.BackgroundNorm
        return cell
    }

    private func setupPaletteCell(indexPath: IndexPath) -> LabelPaletteCell {
        let identifier = LabelPaletteCell.defaultID()
        guard let cell = self.tableView
                .dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? LabelPaletteCell else {
            return .init()
        }
        cell.selectionStyle = .none
        cell.config(colors: self.viewModel.colors,
                    selected: self.viewModel.iconColor,
                    type: self.viewModel.type,
                    delegate: self)
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
        let icon = Asset.icInfoCircle.image
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
        attr[.foregroundColor] = UIColorManager.NotificationError
        instance.textLabel?.attributedText = self.viewModel.deleteTitle.apply(style: attr)
        instance.textLabel?.textAlignment = .center
        instance.addSeparator(padding: 0)
        instance.contentView.backgroundColor = UIColorManager.BackgroundNorm
        return instance
    }

    // MARK: didSelectRow
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)
        switch self.viewModel.section[indexPath.section] {
        case .name, .palette, .colorInherited:
            return
        case .folderOptions:
            if indexPath.row == 0 {
                self.showParentFolderSheet()
            }
        case .delete:
            self.clickDeleteButton()
        }
    }

}

extension NEWLabelEditViewController: LabelPaletteCellDelegate, LabelNameDelegate {
    func nameChanged(name: String) {
        self.viewModel.update(name: name)
    }

    func selectColor(hex: String, index: Int) {
        self.viewModel.update(iconColor: hex)
    }
}
