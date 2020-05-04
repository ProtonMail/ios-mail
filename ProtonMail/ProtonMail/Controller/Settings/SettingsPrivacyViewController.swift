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
import PMKeymaker

class SettingsPrivacyViewController: UITableViewController, ViewModelProtocol, CoordinatedNew {
    internal var viewModel : SettingsPrivacyViewModel!
    internal var coordinator : SettingsPrivacyCoordinator?
    
    func set(viewModel: SettingsPrivacyViewModel) {
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
        self.tableView.register(SettingsGeneralCell.self)
        self.tableView.register(SettingsTwoLinesCell.self)
        self.tableView.register(SwitchTableViewCell.self)
        self.tableView.tableFooterView = UIView()
        self.tableView.backgroundColor = UIColor(hexString: "E2E6E8", alpha: 1.0)
        
//        self.tableView.estimatedRowHeight = 36.0
        self.tableView.rowHeight = 50.0// UITableView.automaticDimension
    }
    
    private func updateTitle() {
        self.title = LocalString._privacy
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
    }
    
    ///MARK: -- table view delegate
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.privacySections.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let item = self.viewModel.privacySections[row]
        switch item {
        case .autoLoadImage:
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.CellID, for: indexPath)
            cell.accessoryType = UITableViewCell.AccessoryType.none
            cell.selectionStyle = UITableViewCell.SelectionStyle.none
            if let c = cell as? SwitchTableViewCell {
                let userinfo = self.viewModel.userInfo
                let userService = self.viewModel.user.userService
                c.configCell(item.description, bottomLine: "", status: userinfo.autoShowRemote, complete: { (cell, newStatus,  feedback: @escaping SwitchTableViewCell.ActionStatus) -> Void in
                    if let indexp = tableView.indexPath(for: cell!), indexPath == indexp {
                        let view = UIApplication.shared.keyWindow ?? UIView()
                        MBProgressHUD.showAdded(to: view, animated: true)
                        userService.updateAutoLoadImage(auth: self.viewModel.user.auth, user: userinfo,
                                                        remote: newStatus, completion: { (_, _, error) in
                            MBProgressHUD.hide(for: view, animated: true)
                            if let error = error {
                                feedback(false)
                                let alertController = error.alertController()
                                alertController.addOKAction()
                                self.present(alertController, animated: true, completion: nil)
                            } else {
                                self.viewModel.user.save()
                                feedback(true)
                            }
                        })
                    } else {
                        feedback(false)
                    }
                })
            }
            return cell
        case .browser:
            let cell = tableView.dequeueReusableCell(withIdentifier: SettingsGeneralCell.CellID, for: indexPath)
            if let c = cell as? SettingsGeneralCell {
                let browser = userCachedStatus.browser
                c.config(left: item.description)
                c.config(right: browser.isInstalled ? browser.title : LinkOpener.safari.title)
            }
            return cell
        case .linkOpeningMode:
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.CellID, for: indexPath)
            cell.accessoryType = UITableViewCell.AccessoryType.none
            cell.selectionStyle = UITableViewCell.SelectionStyle.none
            if let c = cell as? SwitchTableViewCell {
                let userinfo = self.viewModel.userInfo
                let userService = self.viewModel.user.userService
                c.configCell(item.description, bottomLine: "", status: userinfo.linkConfirmation == .confirmationAlert, complete: { (cell, newStatus,  feedback: @escaping SwitchTableViewCell.ActionStatus) -> Void in
                    if let indexp = tableView.indexPath(for: cell!), indexPath == indexp {
                        let view = UIApplication.shared.keyWindow ?? UIView()
                        MBProgressHUD.showAdded(to: view, animated: true)
                        userService.updateLinkConfirmation(auth: self.viewModel.user.auth, user: userinfo,
                                                           newStatus ? .confirmationAlert : .openAtWill) { userInfo, _, error in
                            MBProgressHUD.hide(for: view, animated: true)
                            if let error = error {
                                feedback(false)
                                let alertController = error.alertController()
                                alertController.addOKAction()
                                self.present(alertController, animated: true, completion: nil)
                            } else {
                                self.viewModel.user.save()
                                feedback(true)
                            }
                        }
                    } else {
                        feedback(false)
                    }
                })
            }
            return cell
        case .metadataStripping:
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.CellID, for: indexPath)
            cell.accessoryType = UITableViewCell.AccessoryType.none
            cell.selectionStyle = UITableViewCell.SelectionStyle.none
            if let c = cell as? SwitchTableViewCell {
                c.configCell(item.description, bottomLine: "", status: userCachedStatus.metadataStripping == .stripMetadata) { cell, newStatus, feedback in
                    userCachedStatus.metadataStripping = newStatus ? .stripMetadata : .sendAsIs
                }
            }
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Key.headerCellHeight
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let row = indexPath.row
        let item = self.viewModel.privacySections[row]
        switch item {
        case .autoLoadImage:
            break
        case .browser:
            let browsers = LinkOpener.allCases.filter {
                $0.isInstalled
            }.compactMap { app in
                return UIAlertAction(title: app.title, style: .default) { [weak self] _ in
                    userCachedStatus.browser = app
                    self?.tableView?.reloadRows(at: [indexPath], with: .fade)
                }
            }
            let alert = UIAlertController(title: nil, message: LocalString._settings_browser_disclaimer, preferredStyle: .actionSheet)
            if let cell = tableView.cellForRow(at: indexPath) {
                alert.popoverPresentationController?.sourceView = cell
                alert.popoverPresentationController?.sourceRect = cell.bounds
            }
            browsers.forEach(alert.addAction)
            alert.addAction(.init(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        case .linkOpeningMode:
            break
        case .metadataStripping:
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
}

extension SettingsPrivacyViewController: Deeplinkable {
    var deeplinkNode: DeepLink.Node {
        return DeepLink.Node(name: String(describing: SettingsTableViewController.self), value: nil)
    }
}
