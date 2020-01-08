//
//  SettingsTableViewController.swift
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

class SettingsDeviceViewController: ProtonMailTableViewController, ViewModelProtocol, CoordinatedNew {
    
    struct CellKey {
        static let headerCell : String        = "header_cell"
        static let headerCellHeight : CGFloat = 36.0
        /// cells
        static let oneLineCell         = "settings_device_general"
//        let SettingSingalSingleLineCell   = "settings_general_single_line"
//        let SettingTwoLinesCell           = "settings_twolines"
//        let SettingDomainsCell            = "setting_domains"
//        let SettingStorageCell            = "setting_storage_cell"
//        let SingleTextCell                = "single_text_cell"
//        let SwitchCell                    = "switch_table_view_cell"
        
    }
    
    internal var viewModel : SettingsDeviceViewModel!
    internal var coordinator : SettingsDeviceCoordinator?
    
    func set(viewModel: SettingsDeviceViewModel) {
        self.viewModel = viewModel
    }
    
    func set(coordinator: SettingsDeviceCoordinator) {
        self.coordinator = coordinator
    }
    
    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }
    
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        //        self.restorationClass = SettingsTableViewController.self
        self.updateTitle()
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: CellKey.headerCell)
    }
    
    private func updateTitle() {
        self.title = LocalString._menu_settings_title
    }

    
//    //TODO:: move to view model
//    var userManager : UserManager {
//        get {
//            let users : UsersManager = sharedServices.get()
//            return users.firstUser
//        }
//    }
    
    //
    var cleaning : Bool      = false
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        self.updateProtectionItems()
////        userManager.userInfo.passwor
//        if sharedUserDataService.passwordMode == 1 {
//            setting_general_items = [.notifyEmail, .singlePWD, .autoLoadImage, .linkOpeningMode, .browser, .metadataStripping, .cleanCache]
//        } else {
//            setting_general_items = [.notifyEmail, .loginPWD, .mbp, .autoLoadImage, .linkOpeningMode, .browser, .metadataStripping, .cleanCache]
//        }
//        if #available(iOS 10.0, *), Constants.Feature.snoozeOn {
//            setting_general_items.append(.notificationsSnooze)
//        }
//        
//        multi_domains = self.userManager.addresses
//        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    internal func updateProtectionItems() {
//        setting_protection_items = []
//        switch UIDevice.current.biometricType {
//        case .none:
//            break
//        case .touchID:
//            setting_protection_items.append(.touchID)
//            break
//        case .faceID:
//            setting_protection_items.append(.faceID)
//            break
//        }
//        setting_protection_items.append(.pinCode)
//        if userCachedStatus.isPinCodeEnabled || userCachedStatus.isTouchIDEnabled {
//            setting_protection_items.append(.enterTime)
//        }
    }
    
    internal func updateTableProtectionSection() {
        self.updateProtectionItems()
//        if let index = self.viewModel.sections.firstIndex(of: SettingSections.protection) {
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
                return 1
            case .app:
                return self.viewModel.appSettigns.count
            case .info:
                return 1
            }
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        let eSection = self.viewModel.sections[section]
        
        switch eSection {
        case .account:
            let cell = tableView.dequeueReusableCell(withIdentifier: CellKey.oneLineCell, for: indexPath)
            if let c = cell as? SettingsDeviceGeneralCell {
                c.configCell(self.viewModel.email, right: "")
            }
            return cell
        case .app:
            let item = self.viewModel.appSettigns[row]
            let cell = tableView.dequeueReusableCell(withIdentifier: CellKey.oneLineCell, for: indexPath)
            if let c = cell as? SettingsDeviceGeneralCell {
                switch item {
                case .autolock:
                    c.configCell(item.description, right: "off")
                case .language:
                    let language: ELanguage =  LanguageManager.currentLanguageEnum()
                    c.configCell(item.description, right: language.nativeDescription)
                case .combinContacts:
                    c.configCell(item.description, right: "off")
                case .cleanCache:
                    c.configCell(item.description, right: "")
                }
            }
            return cell
        case .info:
            let cell = tableView.dequeueReusableCell(withIdentifier: CellKey.oneLineCell, for: indexPath)
            if let c = cell as? SettingsDeviceGeneralCell {
                c.configCell("AppVersion", right: self.viewModel.appVersion())
            }
            return cell
        }
    }
    
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: CellKey.headerCell)
        if let headerCell = header {
            headerCell.textLabel?.font = Fonts.h6.regular
            headerCell.textLabel?.textColor = UIColor.ProtonMail.Gray_8E8E8E
            let eSection = self.viewModel.sections[section]
            headerCell.textLabel?.text = eSection.description
        }
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CellKey.headerCellHeight
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        let eSection = self.viewModel.sections[section]
        switch eSection {
        case .account:
            self.coordinator?.go(to: .accountSetting)
        case .app:
            let item = self.viewModel.appSettigns[row]
            switch item {
            case .autolock:
                break
            case .language:
                break
            case .combinContacts:
                break
            case .cleanCache:
                if !cleaning {
                    cleaning = true
                    let nview = self.navigationController?.view ?? UIView()
                    let hud : MBProgressHUD = MBProgressHUD.showAdded(to: nview, animated: true)
                    hud.label.text = LocalString._settings_resetting_cache
                    hud.removeFromSuperViewOnHide = true
                    
                    
                    self.viewModel.userManager.messageService.cleanLocalMessageCache() { task, res, error in
                        hud.mode = MBProgressHUDMode.text
                        hud.label.text = LocalString._general_done_button
                        hud.hide(animated: true, afterDelay: 1)
                        self.cleaning = false
                    }
                }
            }
        case .info:
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

}

@available(iOS, deprecated: 13.0, message: "iOS 13 restores state via Deeplinkable conformance")
extension SettingsDeviceViewController: UIViewControllerRestoration {
    static func viewController(withRestorationIdentifierPath identifierComponents: [String], coder: NSCoder) -> UIViewController? {
        guard let data = coder.decodeObject(forKey: "viewModel") as? Data,
            let viewModel = (try? JSONDecoder().decode(SettingsViewModelImpl.self, from: data)) else
        {
            return nil
        }

        let next = UIStoryboard(name: "Settings", bundle: .main).make(SettingsTableViewController.self)
        next.set(viewModel: viewModel)
        next.set(coordinator: .init(vc: next, vm: viewModel, services: sharedServices))

        return next
    }
    
    override func encodeRestorableState(with coder: NSCoder) {
        if let viewModel = self.viewModel as? SettingsViewModelImpl,
            let data = try? JSONEncoder().encode(viewModel)
        {
            coder.encode(data, forKey: "viewModel")
        }
        super.encodeRestorableState(with: coder)
    }
    
    override func applicationFinishedRestoringState() {
        super.applicationFinishedRestoringState()
        UIViewController.setup(self, self.menuButton, self.shouldShowSideMenu())
    }
}

extension SettingsDeviceViewController: Deeplinkable {
    var deeplinkNode: DeepLink.Node {
        return DeepLink.Node(name: String(describing: SettingsTableViewController.self), value: nil)
    }
}
