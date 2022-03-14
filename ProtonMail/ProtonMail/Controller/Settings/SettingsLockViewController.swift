//
//  SettingsLockViewController.swift
//  ProtonMail - Created on 3/17/15.
//
//
//  Copyright (c) 2019 Proton Technologies AG
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

import UIKit
import MBProgressHUD
import Masonry
import ProtonCore_Keymaker
import ProtonCore_UIFoundations

class SettingsLockViewController: UITableViewController, ViewModelProtocol, CoordinatedNew, AccessibleView {
    internal var viewModel: SettingsLockViewModel!
    internal var coordinator: SettingsLockCoordinator?

    struct Key {
        static let headerCell: String = "header_cell"
        static let headerCellHeight: CGFloat = 52.0
        static let cellHeight: CGFloat = 48.0
        static let changePinCodeCell: String = "ChangePinCode"
        static let enableProtectionCell: String = "EnableProtection"
        static let switchCell: String = "switch_table_view_cell"
    }

    func set(viewModel: SettingsLockViewModel) {
        self.viewModel = viewModel
    }

    func set(coordinator: SettingsLockCoordinator) {
        self.coordinator = coordinator
    }

    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateTitle()

        self.view.backgroundColor = ColorProvider.BackgroundSecondary

        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: Key.headerCell)

        self.tableView.estimatedSectionHeaderHeight = Key.headerCellHeight
        self.tableView.sectionHeaderHeight = UITableView.automaticDimension

        self.tableView.estimatedRowHeight = Key.cellHeight
        self.tableView.rowHeight = UITableView.automaticDimension

        self.tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        self.tableView.register(SettingsGeneralCell.self)
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: Key.changePinCodeCell)
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: Key.enableProtectionCell)
        self.tableView.register(SwitchTableViewCell.self)

        generateAccessibilityIdentifiers()
    }

    private func updateTitle() {
        self.title = viewModel.appPINTitle
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateTableProtectionSection()
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    private func updateTableProtectionSection() {
        self.viewModel.updateProtectionItems()
        self.tableView.reloadData()
    }

    // MARK: - - table view delegate
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < self.viewModel.sections.count else {
            return 0
        }
        let eSection = self.viewModel.sections[section]
        switch eSection {
        case .enableProtection:
            return self.viewModel.protectionItems.count
        case .changePin:
            return 1
        case .timing:
            return 1
        case .mainKey:
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        let eSection = self.viewModel.sections[section]
        switch eSection {
        case .enableProtection:
            let cell = tableView.dequeueReusableCell(withIdentifier: Key.enableProtectionCell, for: indexPath)
            let item = self.viewModel.protectionItems[row]
            switch item {
            case .none:
                cell.accessoryType = self.viewModel.lockOn ? .none : .checkmark
                cell.accessibilityIdentifier = "SettingsLockView.nonCell"
            case .pinCode:
                cell.accessoryType = self.viewModel.isPinCodeEnabled ? .checkmark : .none
                cell.accessibilityIdentifier = "SettingsLockView.pinCodeCell"
            case .faceId:
                cell.accessoryType = self.viewModel.isTouchIDEnabled ? .checkmark : .none
                cell.accessibilityIdentifier = "SettingsLockView.faceIdCell"
            }

            let title = (item == .faceId ? viewModel.getBioProtectionTitle() : item.description)
            cell.textLabel?.attributedText = NSAttributedString(string: title,
                                                                attributes: FontManager.Default)
            cell.selectionStyle = UITableViewCell.SelectionStyle.none
            cell.textLabel?.translatesAutoresizingMaskIntoConstraints = false
            cell.textLabel?.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16.0).isActive = true
            cell.textLabel?.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor).isActive = true
            return cell
        case .changePin:
            let cell = tableView.dequeueReusableCell(withIdentifier: Key.changePinCodeCell, for: indexPath)
            var attribute = FontManager.Default
            attribute[.foregroundColor] = ColorProvider.InteractionNorm
            cell.textLabel?.attributedText = NSAttributedString(string: LocalString._settings_change_pin_code_title, attributes: attribute)
            return cell
        case .timing:
            let cell = tableView.dequeueReusableCell(withIdentifier: SettingsGeneralCell.CellID, for: indexPath) as! SettingsGeneralCell

            let timeIndex = userCachedStatus.lockTime.rawValue
            var text = String(format: LocalString._settings_auto_lock_minutes, timeIndex)
            if timeIndex == -1 {
                text = LocalString._general_none
            } else if timeIndex == 0 {
                text = LocalString._settings_every_time_enter_app
            } else if timeIndex == 1 {
                text = String(format: LocalString._settings_auto_lock_minute, timeIndex)
            }
            cell.configureCell(left: eSection.description.string, right: text, imageType: .arrow)
            return cell
        case .mainKey:
            let cell = tableView.dequeueReusableCell(withIdentifier: Key.switchCell, for: indexPath) as! SwitchTableViewCell

            let appKeyEnabled = self.viewModel.isAppKeyEnabled
            cell.configCell(eSection.description.string, bottomLine: "", status: appKeyEnabled) { _, newStatus, feedback in
                if newStatus {
                    if let randomProtection = RandomPinProtection.randomPin {
                        keymaker.deactivate(randomProtection)
                    }
                    userCachedStatus.keymakerRandomkey = nil
                } else {
                    userCachedStatus.keymakerRandomkey = String.randomString(32)
                    if let randomProtection = RandomPinProtection.randomPin {
                        keymaker.activate(randomProtection) { _ in

                        }
                    }
                }
                feedback(true)
            }
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let eSection = self.viewModel.sections[section]
        guard !eSection.description.string.isEmpty else {
            return nil
        }

        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: Key.headerCell)
        header?.contentView.subviews.forEach { $0.removeFromSuperview() }

        if let headerCell = header {
            let textLabel = UILabel()
            textLabel.attributedText = eSection.description
            textLabel.translatesAutoresizingMaskIntoConstraints = false
            textLabel.numberOfLines = 0
            headerCell.contentView.addSubview(textLabel)

            textLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 20).isActive = true
            textLabel.topAnchor.constraint(equalTo: headerCell.contentView.topAnchor, constant: 24.0).isActive = true
            textLabel.leadingAnchor.constraint(equalTo: headerCell.contentView.leadingAnchor, constant: 16.0).isActive = true
            textLabel.trailingAnchor.constraint(equalTo: headerCell.contentView.trailingAnchor, constant: -16.0).isActive = true
            textLabel.bottomAnchor.constraint(equalTo: headerCell.contentView.bottomAnchor, constant: -8.0).isActive = true
        }
        return header
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let eSection = self.viewModel.sections[section]
        switch eSection {
        case .enableProtection:
            let item = self.viewModel.protectionItems[indexPath.row]
            switch item {
            case .none:
                self.viewModel.disableProtection()
                self.updateTableProtectionSection()
            case .pinCode:
                self.coordinator?.go(to: .pinCodeSetup)
                // add call back or check in view will appear
            case .faceId:
                self.viewModel.enableBioProtection { [weak self] in
                    self?.updateTableProtectionSection()
                }
            }
        case .changePin:
            self.coordinator?.go(to: .pinCodeSetup)
        case .timing:
            let alertController = UIAlertController(title: LocalString._settings_auto_lock_time,
                                                    message: nil,
                                                    preferredStyle: .actionSheet)
            alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
            for timeIndex in viewModel.auto_logout_time_options {
                var text = String(format: LocalString._settings_auto_lock_minutes, timeIndex)
                if timeIndex == -1 {
                    text = LocalString._general_none
                } else if timeIndex == 0 {
                    text = LocalString._settings_every_time_enter_app
                } else if timeIndex == 1 {
                    text = String(format: LocalString._settings_auto_lock_minute, timeIndex)
                }
                alertController.addAction(UIAlertAction(title: text, style: .default, handler: { (action) -> Void in
                    userCachedStatus.lockTime = AutolockTimeout(rawValue: timeIndex)
                    DispatchQueue.main.async {
                        tableView.reloadRows(at: [indexPath], with: .fade)
                    }
                }))
            }
            let cell = tableView.cellForRow(at: indexPath)
            alertController.popoverPresentationController?.sourceView = cell ?? self.view
            alertController.popoverPresentationController?.sourceRect = (cell == nil ? self.view.frame : cell!.bounds)
            present(alertController, animated: true, completion: nil)
        case .mainKey:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch self.viewModel.sections[indexPath.section] {
        case .enableProtection, .changePin:
            return Key.cellHeight
        default:
            return UITableView.automaticDimension
        }
    }
}

extension SettingsLockViewController: Deeplinkable {
    var deeplinkNode: DeepLink.Node {
        return DeepLink.Node(name: String(describing: SettingsTableViewController.self), value: nil)
    }
}
