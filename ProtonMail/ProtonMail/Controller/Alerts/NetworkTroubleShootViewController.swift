//
//  NetworkTroubleShootViewController.swift
//  ProtonMail - Created on 3/01/2020.
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


class NetworkTroubleShootViewController: UITableViewController, ViewModelProtocol, CoordinatedNew {

    public enum Item: Int, CustomStringConvertible {
        public var description: String {
            return ""
        }
        
        case allowSwitch = 0
        case noInternetNotes = 1
        case ipsNotes = 2
        case blockNotes = 3
        case antivirusNotes = 4
        case firewallNotes = 5
        case downtimeNotes = 6
        case otherNotes = 7
        
        public var top : String {
            switch(self){
            case .allowSwitch:
                return "Allow alternative routing"
            case .noInternetNotes:
                return "No internet connection"
            case .ipsNotes:
                return "Internet Service Provider (ISP) problem"
            case .blockNotes:
                return "Government block"
            case .antivirusNotes:
                return "Antivirus interference"
            case .firewallNotes:
                return "Proxy/Firewall interference"
            case .downtimeNotes:
                return "Proton is down"
            case .otherNotes:
                return "Still can't find a solution"
            }
        }
        
        public var bottom : String {
            switch(self){
            case .allowSwitch:
                return "In case Proton sites are blocked, this setting allows the app to try alternative network routing to reach Proton, which can be useful for bypassing firewalls or network issues. We recommend keeping this setting on for greater reliability. [Learn more]"
            case .noInternetNotes:
                return "Please make sure that your internet connection is working."
            case .ipsNotes:
                return "Try connecting to Proton from a different network (or use ProtonVPN or Tor)."
            case .blockNotes:
                return "Your country may be blocking access to Proton. Try using ProtonVPN (or any other VPN) or Tor to access Proton."
            case .antivirusNotes:
                return "Temporarily disable or remove your antivirus software."
            case .firewallNotes:
                return "Disable any proxies or firewalls, or contact your network administrator."
            case .downtimeNotes:
                return "Check Proton Status for our system status."
            case .otherNotes:
                return "Contact us directly through our support form, email (support@protonmail.com), or Twitter."
            }
        }
    }
    
    internal var viewModel : NetworkTroubleShootViewModel!
    internal var coordinator : NetworkTroubleShootCoordinator?
    
    func set(viewModel: NetworkTroubleShootViewModel) {
        self.viewModel = viewModel
    }
    
    func set(coordinator: NetworkTroubleShootCoordinator) {
        self.coordinator = coordinator
    }
    
    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }
    
    ///
    var items : [Item] = [.allowSwitch,.noInternetNotes,.ipsNotes,.blockNotes,.antivirusNotes,.firewallNotes,.downtimeNotes,.otherNotes]
    
    /// cells
    let SettingSingalLineCell         = "settings_general"
    let SettingSingalSingleLineCell   = "settings_general_single_line"
    let SettingTwoLinesCell           = "settings_twolines"
    let SettingDomainsCell            = "setting_domains"
    let SettingStorageCell            = "setting_storage_cell"
    let HeaderCell                    = "header_cell"
    let SingleTextCell                = "single_text_cell"
    let SwitchCell                    = "switch_table_view_cell"
    
    //
    let CellHeight : CGFloat = 30.0
    var cleaning : Bool      = false
    
    //
    @IBOutlet var settingTableView: UITableView!
    
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        self.restorationClass = SettingsTableViewController.self
        self.updateTitle()
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: HeaderCell)
        
        self.tableView.estimatedSectionHeaderHeight = CellHeight
        self.tableView.sectionHeaderHeight = UITableView.automaticDimension
        
        self.tableView.estimatedRowHeight = CellHeight
        self.tableView.rowHeight = UITableView.automaticDimension
        
        self.tableView.noSeparatorsBelowFooter()
        
        
        let newBackButton = UIBarButtonItem(title: LocalString._general_back_action,
                                            style: UIBarButtonItem.Style.plain,
                                            target: self,
                                            action: #selector(NetworkTroubleShootViewController.back(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton
    }
    
    @objc func back(sender: UIBarButtonItem) {
        if self.presentingViewController != nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            let _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    private func updateTitle() {
        self.title = "TroubleShooting"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    ///MARK: -- table view delegate
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: SwitchCell, for: indexPath)
        if let cellout = cell as? SwitchTableViewCell {
            if item == .allowSwitch {
                if let cellout = cell as? SwitchTableViewCell {
                    cellout.accessoryType = UITableViewCell.AccessoryType.none
                    cellout.selectionStyle = UITableViewCell.SelectionStyle.none
                    cellout.configCell(item.top, bottomLine: item.bottom, showSwitcher: true, status: DoHMail.default.status == .on) { cell, newStatus, feedback in
                        if newStatus {
                            DoHMail.default.status = .on
                            userCachedStatus.isDohOn = true
                        } else {
                            DoHMail.default.status = .off
                            userCachedStatus.isDohOn = false
                        }
                    }
                }
            } else {
                cellout.accessoryType = UITableViewCell.AccessoryType.none
                cellout.selectionStyle = UITableViewCell.SelectionStyle.none
                cellout.configCell(item.top, bottomLine: item.bottom, showSwitcher: false, status: false, complete: nil)
            }
        }
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 8
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
