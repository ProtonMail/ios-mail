//
//  SettingsPrivacyViewController.swift
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
import Keymaker

class SettingsPrivacyViewController: UITableViewController, ViewModelProtocol, CoordinatedNew {
    internal var viewModel : SettingsAccountViewModel!
    internal var coordinator : SettingsPrivacyCoordinator?
    
    func set(viewModel: SettingsAccountViewModel) {
        self.viewModel = viewModel
    }
    
    func set(coordinator: SettingsPrivacyCoordinator) {
        self.coordinator = coordinator
    }
    
    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }
    
    struct Key {
        static let headerCell : String        = "header_cell"
        static let headerCellHeight : CGFloat = 36.0
    }
    
    /// cells
//    let SettingSingalLineCell         = "settings_general"
//    let SettingSingalSingleLineCell   = "settings_general_single_line"
//    let SettingTwoLinesCell           = "settings_twolines"
//    let SettingDomainsCell            = "setting_domains"
//    let SettingStorageCell            = "setting_storage_cell"
//    let HeaderCell                    = "header_cell"
//    let SingleTextCell                = "single_text_cell"
//    let SwitchCell                    = "switch_table_view_cell"

    //
    @IBOutlet var settingTableView: UITableView!
    
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateTitle()
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: Key.headerCell)
    }
    
    private func updateTitle() {
        self.title = LocalString._menu_settings_title
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateProtectionItems()

        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    internal func updateProtectionItems() {
        
    }
    
    internal func updateTableProtectionSection() {
        self.updateProtectionItems()
//        if let index = setting_headers.firstIndex(of: SettingSections.protection) {
//            self.settingTableView.reloadSections(IndexSet(integer: index), with: .fade)
//        }
    }
    
    ///MARK: -- table view delegate
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.sections.count
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.viewModel.sections.count > section {
            switch( self.viewModel.sections[section]) {
            case .account:
                return self.viewModel.accountItems.count
            case .addresses:
                return 1 // self.viewModel.appSettigns.count
            case .snooze:
                return 0
            case .mailbox:
                return 1
            }
        }
        return 0
    }
    
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let section = indexPath.section
//        let row = indexPath.row
//        let eSection = self.viewModel.sections[section]
//
//        switch eSection {
//        case .account:
//            let cell = tableView.dequeueReusableCell(withIdentifier: SettingSingalLineCell, for: indexPath)
//            if let c = cell as? GeneralSettingViewCell {
//                let item = self.viewModel.accountItems[row]
//                c.configCell(item.description, right: "")
//            }
//            return cell
//        case .addresses:
//            let cell = tableView.dequeueReusableCell(withIdentifier: SettingSingalLineCell, for: indexPath)
//            if let c = cell as? GeneralSettingViewCell {
//                let item = self.viewModel.accountItems[row]
//                c.configCell(item.description, right: "")
//            }
//            return cell
//        case .snooze:
//            let cell = tableView.dequeueReusableCell(withIdentifier: SettingSingalLineCell, for: indexPath)
//            if let c = cell as? SettingsDeviceGeneralCell {
//                c.configCell("AppVersion", right: "")
//            }
//            return cell
//        case .mailbox:
//            let cell = tableView.dequeueReusableCell(withIdentifier: SettingSingalLineCell, for: indexPath)
//            if let c = cell as? SettingsDeviceGeneralCell {
//                c.configCell("AppVersion", right: "")
//            }
//            return cell
//        }
//    }
//
//
//    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: CellKey.headerCell)
//        if let headerCell = header {
//            headerCell.textLabel?.font = Fonts.h6.regular
//            headerCell.textLabel?.textColor = UIColor.ProtonMail.Gray_8E8E8E
//            let eSection = self.viewModel.sections[section]
//            headerCell.textLabel?.text = eSection.description
//        }
//        return header
//    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Key.headerCellHeight
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        let eSection = self.viewModel.sections[section]
        switch eSection {
        case .account:
//            self.coordinator?.go(to: .accountSetting)
            break
        case .addresses:
            //            let item = self.viewModel.appSettigns[row]
            break
        case .snooze:
            break
        case .mailbox:
            break
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
//    @objc func tableView(_ tableView: UITableView, moveRowAtIndexPath fromIndexPath: IndexPath, toIndexPath: IndexPath) {

//    }
    
}

extension SettingsPrivacyViewController: Deeplinkable {
    var deeplinkNode: DeepLink.Node {
        return DeepLink.Node(name: String(describing: SettingsTableViewController.self), value: nil)
    }
}
