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
import PMKeymaker
import Masonry

class SettingsLockViewController: UITableViewController, ViewModelProtocol, CoordinatedNew {
    internal var viewModel : SettingsLockViewModel!
    internal var coordinator : SettingsLockCoordinator?
    
    struct Key {
        static let headerCell : String        = "header_cell"
        static let headerCellHeight : CGFloat = 36.0
        static let cellHeight: CGFloat = 44.0
        
        static let settingSingalLineCell         = "settings_general"
        static let SwitchCell                    = "switch_table_view_cell"
        static let SettingTwoLinesCell           = "settings_twolines"
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
    
    var protection_auto_logout : [Int]                   = [-1, 0, 1, 2, 5,
                                                            10, 15, 30, 60]
    
    var lockText = LocalString._enable_pin
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateTitle()
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: Key.headerCell)
        
        self.tableView.estimatedSectionFooterHeight = Key.headerCellHeight
        self.tableView.sectionFooterHeight = UITableView.automaticDimension
        
        self.tableView.estimatedRowHeight = Key.cellHeight
        self.tableView.rowHeight = UITableView.automaticDimension
    }
    
    private func updateTitle() {
        self.title = LocalString._auto_lock
        
        switch UIDevice.current.biometricType {
        case .none:
            self.title = LocalString._pin
        case .touchID:
            self.title = LocalString._pin_and_touch_id
            self.lockText = LocalString._enable_pin_or_touch_id
        case .faceID:
            self.title = LocalString._pin_and_face_id
            self.lockText = LocalString._enable_pin_or_face_id
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateTableProtectionSection()
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    internal func updateTableProtectionSection() {
        self.viewModel.updateProtectionItems()
        self.tableView.reloadData()
    }
    
    ///MARK: -- table view delegate
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < self.viewModel.sections.count else {
            return 0
        }
        let eSection = self.viewModel.sections[section]
        switch eSection {
        case .lock:
            return 1
        case .type:
            return self.viewModel.lockItems.count
        case .timer:
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        let eSection = self.viewModel.sections[section]
        switch eSection {
        case .lock:
            let cell = tableView.dequeueReusableCell(withIdentifier: Key.SwitchCell, for: indexPath)
            cell.accessoryType = UITableViewCell.AccessoryType.none
            cell.selectionStyle = UITableViewCell.SelectionStyle.none
            if let c = cell as? SwitchTableViewCell {
                c.configCell(self.lockText, bottomLine: "", status: self.viewModel.lockOn, complete: { (cell, newStatus, feedback) -> Void in
                    let ison = self.viewModel.lockOn
                    self.viewModel.lockOn = !ison
                    self.updateTableProtectionSection()
                })
            }
            return cell
        case .type:
            let item = self.viewModel.lockItems[row]
            switch item {
            case .pin:
                let cell = tableView.dequeueReusableCell(withIdentifier: Key.SwitchCell, for: indexPath)
                cell.accessoryType = UITableViewCell.AccessoryType.none
                cell.selectionStyle = UITableViewCell.SelectionStyle.none
                if let c = cell as? SwitchTableViewCell {
                    c.configCell(item.description, bottomLine: "", status: userCachedStatus.isPinCodeEnabled, complete: { (cell, newStatus, feedback) -> Void in
                        if let indexp = tableView.indexPath(for: cell!) {
                            if indexPath == indexp {
                                if !userCachedStatus.isPinCodeEnabled {
                                    self.coordinator?.go(to: .pinCode)
                                } else {
                                    keymaker.deactivate(PinProtection(pin: "doesnotmatter"))
                                    feedback(true)
                                    self.updateTableProtectionSection()
                                }
                            } else {
                                feedback(false)
                            }
                        } else {
                            feedback(false)
                        }
                    })
                }
                return cell
            case .touchid, .faceid:
                let cell = tableView.dequeueReusableCell(withIdentifier: Key.SwitchCell, for: indexPath)
                cell.accessoryType = UITableViewCell.AccessoryType.none
                cell.selectionStyle = UITableViewCell.SelectionStyle.none
                if let c = cell as? SwitchTableViewCell {
                    c.configCell(item.description, bottomLine: "", status: userCachedStatus.isTouchIDEnabled, complete: { (cell, newStatus, feedback) -> Void in
                        if let indexp = tableView.indexPath(for: cell!) {
                            if indexPath == indexp {
                                if !userCachedStatus.isTouchIDEnabled {
                                    // Enable Bio
                                    keymaker.activate(BioProtection()) { _ in
                                        self.updateTableProtectionSection()
                                    }
                                } else {
                                    // Disable Bio
                                    keymaker.deactivate(BioProtection())
                                    self.updateTableProtectionSection()
                                }
                            } else {
                                feedback(false)
                            }
                        } else {
                            feedback(false)
                        }
                    })
                }
                return cell
            }
        case .timer:
            let cell = tableView.dequeueReusableCell(withIdentifier: Key.SettingTwoLinesCell, for: indexPath) as! SettingsCell
            cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            
            let timeIndex = userCachedStatus.lockTime.rawValue
            var text = String(format: LocalString._settings_auto_lock_minutes, timeIndex)
            if timeIndex == -1 {
                text = LocalString._general_none
            } else if timeIndex == 0 {
                text = LocalString._settings_every_time_enter_app
            } else if timeIndex == 1{
                text = String(format: LocalString._settings_auto_lock_minute, timeIndex)
            }
            cell.configCell(leftText: eSection.description,
                            rightText: text)
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: Key.headerCell)
        header?.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        if let headerCell = header {
            let textLabel = UILabel()
            
            textLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
            textLabel.adjustsFontForContentSizeCategory = true
            textLabel.numberOfLines = 0
            textLabel.textColor = UIColor.ProtonMail.Gray_8E8E8E
            let eSection = self.viewModel.sections[section]
            textLabel.text = eSection.foot
            
            headerCell.contentView.addSubview(textLabel)
            
            textLabel.mas_makeConstraints({ (make) in
                let _ = make?.top.equalTo()(headerCell.contentView.mas_top)?.with()?.offset()(8)
                let _ = make?.bottom.equalTo()(headerCell.contentView.mas_bottom)?.with()?.offset()(-8)
                let _ = make?.left.equalTo()(headerCell.contentView.mas_left)?.with()?.offset()(8)
                let _ = make?.right.equalTo()(headerCell.contentView.mas_right)?.with()?.offset()(-8)
            })
        }
        return header
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let eSection = self.viewModel.sections[section]
        switch eSection {
        case .lock, .type:
            break
        case .timer:
            let alertController = UIAlertController(title: LocalString._settings_auto_lock_time,
                                                    message: nil,
                                                    preferredStyle: .actionSheet)
            alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
            for timeIndex in protection_auto_logout {
                var text = String(format: LocalString._settings_auto_lock_minutes, timeIndex)
                if timeIndex == -1 {
                    text = LocalString._general_none
                } else if timeIndex == 0 {
                    text = LocalString._settings_every_time_enter_app
                } else if timeIndex == 1{
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
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle.none
    }

    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if sourceIndexPath.section != proposedDestinationIndexPath.section {
            return sourceIndexPath
        }
        else {
            return proposedDestinationIndexPath
        }
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
//        if setting_headers[fromIndexPath.section] == SettingSections.multiDomain {
//            let val = self.multi_domains.remove(at: fromIndexPath.row)
//            self.multi_domains.insert(val, at: toIndexPath.row)
//            //let indexSet = NSIndexSet(index:fromIndexPath.section)
//            tableView.reloadData()
//        }
    }
    
    
    
//    // Override to support rearranging the table view.
//    func tableView(_ tableView: UITableView, moveRowAtIndexPath fromIndexPath: IndexPath, toIndexPath: IndexPath) {

//    }
    
}

extension SettingsLockViewController: Deeplinkable {
    var deeplinkNode: DeepLink.Node {
        return DeepLink.Node(name: String(describing: SettingsTableViewController.self), value: nil)
    }
}
