//
//  SettingsAccountViewController.swift
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
import PMCommon

class SettingsAccountViewController: UITableViewController, ViewModelProtocol, CoordinatedNew {
    internal var viewModel : SettingsAccountViewModel!
    internal var coordinator : SettingsAccountCoordinator?
    
    func set(viewModel: SettingsAccountViewModel) {
        self.viewModel = viewModel
    }
    
    func set(coordinator: SettingsAccountCoordinator) {
        self.coordinator = coordinator
    }
    
    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }
    
    //TODO:: move to view model
    var userManager : UserManager {
        get {
            let users : UsersManager = sharedServices.get()
            return users.firstUser!
        }
    }
    
    struct CellKey {
        static let headerCell : String        = "header_cell"
        static let headerCellHeight : CGFloat = 36.0
        /// cells
        //        static let oneLineCell         = "settings_device_general"
        //        let SettingSingalSingleLineCell   = "settings_general_single_line"
        //        let SettingTwoLinesCell           = "settings_twolines"
        //        let SettingDomainsCell            = "setting_domains"
        //        let SettingStorageCell            = "setting_storage_cell"
        //        let SingleTextCell                = "single_text_cell"
        //        let SwitchCell                    = "switch_table_view_cell"
        
    }
    
    //
    let CellHeight : CGFloat = 30.0
    var cleaning : Bool      = false
    
    //
    @IBOutlet var settingTableView: UITableView!
    
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateTitle()
        
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: CellKey.headerCell)
        self.tableView.register(SettingsGeneralCell.self)
        self.tableView.register(SettingsTwoLinesCell.self)
        
        self.tableView.estimatedRowHeight = 36.0
        self.tableView.rowHeight = UITableView.automaticDimension
    }
    
    private func updateTitle() {
        self.title = LocalString._account_settings
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.viewModel.updateItems()
        navigationController?.setNavigationBarHidden(false, animated: true)
        self.tableView.reloadData()
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
                return self.viewModel.addrItems.count
            case .snooze:
                return 0
            case .mailbox:
                return self.viewModel.mailboxItems.count
            }
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //if later we have different cells, could move cell id in viewmodel or move the dequeue in switch case.
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsGeneralCell.CellID, for: indexPath)
        
        let section = indexPath.section
        let row = indexPath.row
        let eSection = self.viewModel.sections[section]
        
        switch eSection {
        case .account:
            if let c = cell as? SettingsGeneralCell {
                c.accessoryType = .disclosureIndicator
                let item = self.viewModel.accountItems[row]
                c.config(left: item.description)
                switch item {
                case .singlePassword, .loginPassword, .mailboxPassword:
                    c.config(right: "****")
                case .recovery:
                    c.config(right: self.viewModel.recoveryEmail)
                case .storage:
                    c.accessoryType = .none
                    c.config(right: self.viewModel.storageText)
                }
            }
        case .addresses:
            if let c = cell as? SettingsGeneralCell {
                c.accessoryType = .disclosureIndicator
                let item = self.viewModel.addrItems[row]
                c.config(left: item.description)
                switch item {
                case .addr:
                    c.config(right: self.viewModel.email)
                case .displayName:
                    c.config(right: self.viewModel.displayName)
                case .signature:
                    c.config(right: self.viewModel.defaultSignatureStatus)
                case .mobileSignature:
                    c.config(right: self.viewModel.defaultMobileSignatureStatus)
                }
            }
            return cell
        case .snooze:
            if let c = cell as? SettingsGeneralCell {
                c.accessoryType = .disclosureIndicator
                c.config(left: "AppVersion")
                c.config(right: "")
            }
        case .mailbox:
            if let c = cell as? SettingsGeneralCell {
                let item = self.viewModel.mailboxItems[row]
                c.config(left: item.description)
                switch item {
                case .privacy:
                    c.config(right: "")
                case .search:
                    c.config(right: "off")
                case .labelFolder:
                    c.config(right: "")
                case .gestures:
                    c.config(right: "")
                case .storage:
                    c.config(right: "100 MB (disabled)")
                }
            }
        }

        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: CellKey.headerCell)
        header?.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        if let headerCell = header {
            let textLabel = UILabel()
            
            textLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
            textLabel.adjustsFontForContentSizeCategory = true
            textLabel.numberOfLines = 0
            textLabel.textColor = UIColor.ProtonMail.Gray_8E8E8E
            let eSection = self.viewModel.sections[section]
            textLabel.text = eSection.description
            
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
    
    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return CellKey.headerCellHeight
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        let eSection = self.viewModel.sections[section]
        switch eSection {
        case .account:
            let item = self.viewModel.accountItems[row]
            switch item {
            case .singlePassword:
                self.coordinator?.go(to: .singlePwd)
            case .loginPassword:
                self.coordinator?.go(to: .loginPwd)
            case .mailboxPassword:
                self.coordinator?.go(to: .mailboxPwd)
            case .recovery:
                self.coordinator?.go(to: .recoveryEmail)
            case .storage:
                break
            }
        case .addresses:
            if self.viewModel.addrItems.count > row{
                let item = self.viewModel.addrItems[row]
                switch item {
                case .addr:
                    var needsShow : Bool = false
                    let alertController = UIAlertController(title: LocalString._settings_change_default_address_to, message: nil, preferredStyle: .actionSheet)
                    alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
                    let defaultAddress : Address? = self.userManager.addresses.defaultAddress()
                    for addr in self.userManager.addresses {
                        if addr.status == 1 && addr.receive == 1 {
                            if defaultAddress != addr {
                                needsShow = true
                                alertController.addAction(UIAlertAction(title: addr.email, style: .default, handler: { (action) -> Void in
                                    if addr.send == 0 {
                                        if addr.email.lowercased().range(of: "@pm.me") != nil {
                                            let msg = String(format: LocalString._settings_change_paid_address_warning, addr.email)
                                            let alertController = msg.alertController()
                                            alertController.addOKAction()
                                            self.present(alertController, animated: true, completion: nil)
                                        }
                                        return
                                    }
                                    
                                    var newAddrs = [Address]()
                                    var newOrder = [String]()
                                    newAddrs.append(addr)
                                    newOrder.append(addr.address_id)
                                    var order = 1
                                    addr.order = order
                                    order += 1
                                    for oldAddr in self.userManager.addresses {
                                        if oldAddr != addr {
                                            newAddrs.append(oldAddr)
                                            newOrder.append(oldAddr.address_id)
                                            oldAddr.order = order
                                            order += 1
                                        }
                                    }
                                    let view = UIApplication.shared.keyWindow ?? UIView()
                                    MBProgressHUD.showAdded(to: view, animated: true)
                                    let service = self.userManager.userService
                                    service.updateUserDomiansOrder(auth: self.userManager.auth, user: self.userManager.userInfo,
                                                                   newAddrs,  newOrder:newOrder) { _, _, error in
                                        MBProgressHUD.hide(for: view, animated: true)
                                        if error == nil {
                                            self.userManager.save()
                                        }
                                        DispatchQueue.main.async {
                                            tableView.reloadData()//reloadSections([indexPath], with: .fade)
                                        }
                                    }
                                }))
                            }
                        }
                    }
                    if needsShow {
                        let cell = tableView.cellForRow(at: indexPath)
                        alertController.popoverPresentationController?.sourceView = cell ?? self.view
                        alertController.popoverPresentationController?.sourceRect = (cell == nil ? self.view.frame : cell!.bounds)
                        present(alertController, animated: true, completion: nil)
                    }
                case .displayName:
                    self.coordinator?.go(to: .displayName)
                case .signature:
                     self.coordinator?.go(to: .signature)
                case .mobileSignature:
                    self.coordinator?.go(to: .mobileSignature)
                }
            }
            break
        case .snooze:
            break
        case .mailbox:
            let item = self.viewModel.mailboxItems[row]
            switch item {
            case .privacy:
                self.coordinator?.go(to: .privacy)
            case .search:
                break
            case .labelFolder:
                self.coordinator?.go(to: .lableManager)	
            case .gestures:                
                self.coordinator?.go(to: .swipingGesture)
            case .storage:
                break
            }
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

extension SettingsAccountViewController: Deeplinkable {
    var deeplinkNode: DeepLink.Node {
        return DeepLink.Node(name: String(describing: SettingsTableViewController.self), value: nil)
    }
}
