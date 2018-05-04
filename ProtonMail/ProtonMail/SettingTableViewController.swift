//
//  SettingTableViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/17/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit
import LocalAuthentication
import MBProgressHUD

class SettingTableViewController: ProtonMailViewController {
    
    var setting_headers : [SettingSections]              = [.general,
                                                            .protection,
                                                            .labels,
                                                            .multiDomain,
                                                            .swipeAction,
                                                            .language,
                                                            .storage,
                                                            .version] //.Debug,
    
    var setting_general_items : [SGItems]                = [.notifyEmail, .loginPWD,
                                                            .mbp, .autoLoadImage, .cleanCache]
    var setting_debug_items : [SDebugItem]               = [.queue, .errorLogs]
    
    var setting_swipe_action_items : [SSwipeActionItems] = [.left, .right]
    var setting_swipe_actions : [MessageSwipeAction]     = [.trash, .spam,
                                                            .star, .archive]
    
    var setting_protection_items : [SProtectionItems]    = [] // [.touchID, .pinCode] // [.TouchID, .PinCode, .UpdatePin, .AutoLogout, .EnterTime]
    var setting_addresses_items : [SAddressItems]        = [.addresses,
                                                            .displayName,
                                                            .signature,
                                                            .defaultMobilSign]
    
    var setting_labels_items : [SLabelsItems]            = [.labelFolderManager]
    
    var setting_languages : [ELanguage]                  = ELanguage.allItems()
    
    var protection_auto_logout : [Int]                   = [-1, 0, 1, 2, 5,
                                                            10, 15, 30, 60]
    
    var multi_domains: [Address]!
    var userInfo = sharedUserDataService.userInfo
    
    /// segues
    let NotificationSegue:String      = "setting_notification"
    let DisplayNameSegue:String       = "setting_displayname"
    let SignatureSegue:String         = "setting_signature"
    let MobileSignatureSegue:String   = "setting_mobile_signature"
    let DebugQueueSegue : String      = "setting_debug_queue_segue"
    let kSetupPinCodeSegue : String   = "setting_setup_pingcode"
    let kManagerLabelsSegue : String  = "toManagerLabelsSegue"
    let kLoginpwdSegue:String         = "setting_login_pwd"
    let kMailboxpwdSegue:String       = "setting_mailbox_pwd"
    let kSinglePasswordSegue : String = "setting_single_password_segue"
    /// cells
    let SettingSingalLineCell         = "settings_general"
    let SettingTwoLinesCell           = "settings_twolines"
    let SettingDomainsCell            = "setting_domains"
    let SettingStorageCell            = "setting_storage_cell"
    let HeaderCell                    = "header_cell"
    let SingleTextCell                = "single_text_cell"
    let SwitchCell                    = "switch_table_view_cell"
    let kTouchIDCell                  = "touch_id_switch_table_cell"
    
    //
    let CellHeight : CGFloat = 30.0
    var cleaning : Bool      = false
    
    //
    @IBOutlet weak var editBarButton: UIBarButtonItem!
    @IBOutlet var settingTableView: UITableView!
    
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.updateTitle()
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
        
        if sharedUserDataService.passwordMode == 1 {
            setting_general_items = [.notifyEmail, .singlePWD, .autoLoadImage, .cleanCache]
        } else {
            setting_general_items = [.notifyEmail, .loginPWD, .mbp, .autoLoadImage, .cleanCache]
        }
        
        userInfo = sharedUserDataService.userInfo
        multi_domains = sharedUserDataService.userAddresses
        UIView.setAnimationsEnabled(false)
        settingTableView.reloadData()
        UIView.setAnimationsEnabled(true)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueID:String! = segue.identifier
        switch segueID
        {
        case kLoginpwdSegue:
            let changeLoginPwdView = segue.destination as! ChangePasswordViewController
            changeLoginPwdView.setViewModel(shareViewModelFactoy.getChangeLoginPassword())
        case kMailboxpwdSegue:
            let changeMBPView = segue.destination as! ChangePasswordViewController
            changeMBPView.setViewModel(shareViewModelFactoy.getChangeMailboxPassword())
        case kSinglePasswordSegue:
            let changeMBPView = segue.destination as! ChangePasswordViewController
            changeMBPView.setViewModel(shareViewModelFactoy.getChangeSinglePassword())
        case NotificationSegue:
            let changeMBPView = segue.destination as! SettingDetailViewController
            changeMBPView.setViewModel(shareViewModelFactoy.getChangeNotificationEmail())
        case DisplayNameSegue:
            let changeMBPView = segue.destination as! SettingDetailViewController
            changeMBPView.setViewModel(shareViewModelFactoy.getChangeDisplayName())
        case SignatureSegue:
            let changeMBPView = segue.destination as! SettingDetailViewController
            changeMBPView.setViewModel(shareViewModelFactoy.getChangeSignature())
        case MobileSignatureSegue:
            let changeMBPView = segue.destination as! SettingDetailViewController
            changeMBPView.setViewModel(shareViewModelFactoy.getChangeMobileSignature())
        case kSetupPinCodeSegue:
            let vc = segue.destination as! PinCodeViewController
            vc.viewModel = SetPinCodeModelImpl()
        case kManagerLabelsSegue:
            let vc = segue.destination as! LablesViewController
            vc.viewModel = LabelManagerViewModelImpl()
            self.setPresentationStyleForSelfController(self, presentingController: vc)
        default:
            break
        }
    }
    
    internal func updateProtectionItems() {
        setting_protection_items = []
        switch biometricType {
        case .none:
            break
        case .touchID:
            setting_protection_items.append(.touchID)
            break
        case .faceID:
            setting_protection_items.append(.faceID)
            break
        }
        
        setting_protection_items.append(.pinCode)
        if userCachedStatus.isPinCodeEnabled || userCachedStatus.isTouchIDEnabled {
            setting_protection_items.append(.enterTime)
        }
    }
    
    internal func updateTableProtectionSection() {
        self.updateProtectionItems()
        self.settingTableView.reloadData()
    }
    
    // MARK: - Table view data source
    @objc func numberOfSectionsInTableView(_ tableView: UITableView) -> Int {
        return setting_headers.count
    }
//    func numberOfSections(in tableView: UITableView) -> Int {
//        return setting_headers.count
//    }
//
    @objc func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if setting_headers.count > section {
            switch(setting_headers[section])
            {
            case .debug:
                return setting_debug_items.count
            case .general:
                return setting_general_items.count
            case .multiDomain:
                return setting_addresses_items.count
            case .swipeAction:
                return setting_swipe_action_items.count
            case .storage:
                return 1
            case .version:
                return 0
            case .protection:
                return setting_protection_items.count
            case .language:
                return 1
            case .labels:
                return setting_labels_items.count
            }
        }
        return 0
    }
    
    @objc func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        var cellout : UITableViewCell?
        if setting_headers.count > indexPath.section {
            let setting_item = setting_headers[indexPath.section]
            switch setting_item {
            case .general:
                if setting_general_items.count > indexPath.row {
                    let itme: SGItems = setting_general_items[indexPath.row]
                    switch itme {
                    case .notifyEmail:
                        let cell = tableView.dequeueReusableCell(withIdentifier: SettingTwoLinesCell, for: indexPath) as! SettingsCell
                        cell.LeftText.text = itme.description
                        cell.RightText.text = userInfo?.notificationEmail
                        cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
                        cellout = cell
                    case .loginPWD, .mbp, .singlePWD:
                        let cell = tableView.dequeueReusableCell(withIdentifier: SettingTwoLinesCell, for: indexPath) as! SettingsCell
                        cell.LeftText.text = itme.description
                        cell.RightText.text = LocalString._settings_secret_x_string
                        cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
                        cellout = cell
                    case .cleanCache:
                        let cell = tableView.dequeueReusableCell(withIdentifier: SettingSingalLineCell, for: indexPath) as! GeneralSettingViewCell
                        cell.configCell(itme.description, right: "")
                        cell.accessoryType = UITableViewCellAccessoryType.none
                        cellout = cell
                    case .autoLoadImage:
                        let cell = tableView.dequeueReusableCell(withIdentifier: SwitchCell, for: indexPath) as! SwitchTableViewCell
                        cell.accessoryType = UITableViewCellAccessoryType.none
                        cell.selectionStyle = UITableViewCellSelectionStyle.none
                        cell.configCell(itme.description, bottomLine: "", status: !sharedUserDataService.showShowImageView, complete: { (cell, newStatus,  feedback: @escaping ActionStatus) -> Void in
                            if let indexp = tableView.indexPath(for: cell!) {
                                if indexPath == indexp {
                                    let view = UIApplication.shared.keyWindow
                                    ActivityIndicatorHelper.show(at: view)
                                    sharedUserDataService.updateAutoLoadImage(newStatus == true ? 3 : 0) { _, _, error in
                                        ActivityIndicatorHelper.hide(at: view)
                                        if let error = error {
                                            feedback(false)
                                            let alertController = error.alertController()
                                            alertController.addOKAction()
                                            self.present(alertController, animated: true, completion: nil)
                                        } else {
                                            feedback(true)
                                        }
                                    }
                                } else {
                                    feedback(false)
                                }
                            } else {
                                feedback(false)
                            }
                        })
                        cellout = cell
                    }
                }
            case .protection:
                if setting_protection_items.count > indexPath.row {
                    let item : SProtectionItems = setting_protection_items[indexPath.row]
                    switch item {
                    case .touchID, .faceID:
                        let cell = tableView.dequeueReusableCell(withIdentifier: SwitchCell, for: indexPath) as! SwitchTableViewCell
                        cell.accessoryType = UITableViewCellAccessoryType.none
                        cell.selectionStyle = UITableViewCellSelectionStyle.none
                        cell.configCell(item.description, bottomLine: "", status: userCachedStatus.isTouchIDEnabled, complete: { (cell, newStatus, feedback) -> Void in
                            if let indexp = tableView.indexPath(for: cell!) {
                                if indexPath == indexp {
                                    if !userCachedStatus.isTouchIDEnabled {
                                        // try to enable touch id
                                        let context = LAContext()
                                        // Declare a NSError variable.
                                        var error: NSError?
                                        // Check if the device can evaluate the policy.
                                        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                                            userCachedStatus.isTouchIDEnabled = true
                                            userCachedStatus.touchIDEmail = sharedUserDataService.username ?? ""
                                            self.updateTableProtectionSection()
                                        }
                                        else{
                                            var alertString : String = ""
                                            // If the security policy cannot be evaluated then show a short message depending on the error.
                                            switch error!.code{
                                            case LAError.Code.touchIDNotEnrolled.rawValue:
                                                alertString = LocalString._general_touchid_not_enrolled
                                            case LAError.Code.passcodeNotSet.rawValue:
                                                alertString = LocalString._general_passcode_not_set
                                            case -6:
                                                alertString = error?.localizedDescription ?? LocalString._general_touchid_not_available
                                            default:
                                                // The LAError.TouchIDNotAvailable case.
                                                alertString = LocalString._general_touchid_not_available
                                            }
                                            PMLog.D(alertString)
                                            PMLog.D("\(String(describing: error?.localizedDescription))")
                                            alertString.alertToast()
                                            feedback(false)
                                        }
                                    } else {
                                        userCachedStatus.isTouchIDEnabled = false
                                        userCachedStatus.touchIDEmail = ""
                                        self.updateTableProtectionSection()
                                    }
                                } else {
                                    feedback(false)
                                }
                            } else {
                                feedback(false)
                            }
                        })
                        cellout = cell
                    case .pinCode:
                        let cell = tableView.dequeueReusableCell(withIdentifier: SwitchCell, for: indexPath) as! SwitchTableViewCell
                        cell.accessoryType = UITableViewCellAccessoryType.none
                        cell.selectionStyle = UITableViewCellSelectionStyle.none
                        cell.configCell(item.description, bottomLine: "", status: userCachedStatus.isPinCodeEnabled, complete: { (cell, newStatus, feedback) -> Void in
                            if let indexp = tableView.indexPath(for: cell!) {
                                if indexPath == indexp {
                                    if !userCachedStatus.isPinCodeEnabled {
                                        self.performSegue(withIdentifier: self.kSetupPinCodeSegue, sender: self)
                                    } else {
                                        userCachedStatus.isPinCodeEnabled = false
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
                        cellout = cell
                    case .updatePin:
                        let cell = tableView.dequeueReusableCell(withIdentifier: SettingSingalLineCell, for: indexPath) as! GeneralSettingViewCell
                        cell.configCell(item.description, right: "")
                        cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
                        cellout = cell
                    case .autoLogout:
                        let cell = tableView.dequeueReusableCell(withIdentifier: SwitchCell, for: indexPath) as! SwitchTableViewCell
                        cell.accessoryType = UITableViewCellAccessoryType.none
                        cell.selectionStyle = UITableViewCellSelectionStyle.none
                        cell.configCell(item.description, bottomLine: "", status: userCachedStatus.isPinCodeEnabled, complete: { (cell, newStatus, feedback) -> Void in
                            if let indexp = tableView.indexPath(for: cell!) {
                                if indexPath == indexp {
                                    
                                } else {
                                    feedback(false)
                                }
                            } else {
                                feedback(false)
                            }
                        })
                        cellout = cell
                    case .enterTime:
                        var timeIndex : Int = -1
                        if let t = Int(userCachedStatus.lockTime) {
                            timeIndex = t
                        }
                        var text = String(format: LocalString._settings_auto_lock_minutes, timeIndex)
                        if timeIndex == -1 {
                            text = LocalString._general_none
                        } else if timeIndex == 0 {
                            text = LocalString._settings_every_time_enter_app
                        } else if timeIndex == 1{
                            text = String(format: LocalString._settings_auto_lock_minute, timeIndex)
                        }
                        
                        let cell = tableView.dequeueReusableCell(withIdentifier: SettingTwoLinesCell, for: indexPath) as! SettingsCell
                        cell.LeftText.text = item.description
                        cell.RightText.text = text
                        cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
                        cellout = cell
                    }
                }
            case .labels:
                if setting_labels_items.count > indexPath.row {
                    let label_item = setting_labels_items[indexPath.row]
                    let cell = tableView.dequeueReusableCell(withIdentifier: SettingSingalLineCell, for: indexPath) as! GeneralSettingViewCell
                    cell.configCell(label_item.description, right: "")
                    cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
                    cellout = cell
                }
            case .multiDomain:
                if setting_addresses_items.count > indexPath.row {
                    let address_item: SAddressItems = setting_addresses_items[indexPath.row]
                    switch address_item {
                    case .addresses:
                        let cell = tableView.dequeueReusableCell(withIdentifier: SettingDomainsCell, for: indexPath) as! DomainsTableViewCell
                        if let addr = multi_domains.defaultAddress() {
                            cell.domainText.text = addr.email
                        } else {
                            cell.domainText.text = LocalString._general_unknown_title
                        }
                        cell.defaultMark.text = LocalString._general_default
                        cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
                        cellout = cell
                    case .displayName:
                        let cell = tableView.dequeueReusableCell(withIdentifier: SettingTwoLinesCell, for: indexPath) as! SettingsCell
                        cell.LeftText.text = address_item.description
                        if let addr = sharedUserDataService.userAddresses.defaultAddress() {
                            cell.RightText.text = addr.display_name
                        } else {
                            cell.RightText.text = sharedUserDataService.displayName
                        }
                        cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
                        cellout = cell
                    case .signature:
                        let cell = tableView.dequeueReusableCell(withIdentifier: SettingSingalLineCell, for: indexPath) as! GeneralSettingViewCell
                        cell.configCell(address_item.description, right: "")
                        cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
                        cellout = cell
                    case .defaultMobilSign:
                        let cell = tableView.dequeueReusableCell(withIdentifier: SettingSingalLineCell, for: indexPath) as! GeneralSettingViewCell
                        cell.configCell(address_item.description, right: "")
                        cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
                        cellout = cell
                    }
                }
            case .swipeAction:
                if indexPath.row < setting_swipe_action_items.count {
                    let actionItem = setting_swipe_action_items[indexPath.row]
                    let cell = tableView.dequeueReusableCell(withIdentifier: SettingDomainsCell, for: indexPath) as! DomainsTableViewCell
                    let action = actionItem == .left ? sharedUserDataService.swiftLeft : sharedUserDataService.swiftRight
                    cell.domainText.text = actionItem.description
                    cell.defaultMark.text = action?.description
                    cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
                    cellout = cell
                }
            case .storage:
                let cell = tableView.dequeueReusableCell(withIdentifier: SettingStorageCell, for: indexPath) as! StorageViewCell
                let usedSpace = sharedUserDataService.usedSpace
                let maxSpace = sharedUserDataService.maxSpace
                cell.setValue(usedSpace, maxSpace: maxSpace)
                cell.selectionStyle = UITableViewCellSelectionStyle.none
                cellout = cell
            case .debug:
                if setting_debug_items.count > indexPath.row {
                    let itme: SDebugItem = setting_debug_items[indexPath.row]
                    let cell = tableView.dequeueReusableCell(withIdentifier: SettingTwoLinesCell, for: indexPath) as! GeneralSettingViewCell
                    cell.LeftText.text = itme.description
                    cell.RightText.text  = ""
                    cellout = cell
                }
            case .language:
                let language: ELanguage =  LanguageManager.currentLanguageEnum()
                let cell = tableView.dequeueReusableCell(withIdentifier: SettingSingalLineCell, for: indexPath) as! GeneralSettingViewCell
                cell.configCell(language.description, right: "")
                cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
                cellout = cell
                
            case .version:
                break
            }
        }
        
        if let cellout = cellout {
            return cellout
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: SettingSingalLineCell, for: indexPath) as! GeneralSettingViewCell
            cell.configCell("", right: "")
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            return cell
        }
    }
    
    @objc func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerCell = tableView.dequeueReusableCell(withIdentifier: HeaderCell) as! CustomHeaderView
        if(setting_headers[section] == SettingSections.version){
            var appVersion = "Unkonw Version"
            var libVersion = "| LibVersion: 1.0.0"
            
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                appVersion = "AppVersion: \(version)"
            }
            if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                appVersion = appVersion + " (\(build))"
            }
            
            let lib_v = PMNLibVersion.getLibVersion()
            libVersion = "| LibVersion: \(lib_v)"
            headerCell.headerText.text = appVersion + " " + libVersion
        }
        else
        {
            headerCell.headerText.text = setting_headers[section].description
        }
        return headerCell
    }
    
    @objc func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CellHeight
    }
    
    @objc func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
        if setting_headers.count > indexPath.section {
            let setting_item = setting_headers[indexPath.section]
            switch setting_item {
            case .general:
                if setting_general_items.count > indexPath.row {
                    let general_itme: SGItems = setting_general_items[indexPath.row]
                    switch general_itme {
                    case .notifyEmail:
                        self.performSegue(withIdentifier: NotificationSegue, sender: self)
                    case .loginPWD:
                       // if shard
                        if sharedUserDataService.passwordMode == 1 {
                            let alert = LocalString._general_use_web_reset_pwd.alertController()
                            alert.addOKAction()
                            present(alert, animated: true, completion: nil)
                        } else {
                            self.performSegue(withIdentifier: kLoginpwdSegue, sender: self)
                        }
                    case .mbp:
                        self.performSegue(withIdentifier: kMailboxpwdSegue, sender: self)
                    case .singlePWD:
                        self.performSegue(withIdentifier: kSinglePasswordSegue, sender: self)
                    case .cleanCache:
                        if !cleaning {
                            cleaning = true
                            let nview = self.navigationController?.view
                            let hud : MBProgressHUD = MBProgressHUD.showAdded(to: nview, animated: true)
                            hud.labelText = LocalString._settings_resetting_cache
                            hud.removeFromSuperViewOnHide = true
                            sharedMessageDataService.cleanLocalMessageCache() { task, res, error in
                                hud.mode = MBProgressHUDMode.text
                                hud.labelText = LocalString._general_done_button
                                hud.hide(true, afterDelay: 1)
                                self.cleaning = false
                            }
                        }
                    case .autoLoadImage:
                        break
                    }
                }
            case .debug:
                if setting_debug_items.count > indexPath.row {
                    let debug_item: SDebugItem = setting_debug_items[indexPath.row]
                    switch debug_item {
                    case .queue:
                        self.performSegue(withIdentifier: DebugQueueSegue, sender: self)
                        break
                    case .errorLogs:
                        break
                    }
                }
            case .protection:
                if setting_protection_items.count > indexPath.row {
                    let protection_item: SProtectionItems = setting_protection_items[indexPath.row]
                    switch protection_item {
                    case .touchID, .faceID:
                        break
                    case .pinCode:
                        break
                    case .updatePin:
                        break
                    case .autoLogout:
                        break
                    case .enterTime:
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
                                let _ = self.navigationController?.popViewController(animated: true)
                                userCachedStatus.lockTime = "\(timeIndex)"
                                tableView.reloadData()
                            }))
                        }
                        let cell = tableView.cellForRow(at: indexPath)
                        alertController.popoverPresentationController?.sourceView = cell ?? self.view
                        alertController.popoverPresentationController?.sourceRect = (cell == nil ? self.view.frame : cell!.bounds)
                        present(alertController, animated: true, completion: nil)
                    }
                }
            case .multiDomain:
                if setting_addresses_items.count > indexPath.row {
                    let address_item: SAddressItems = setting_addresses_items[indexPath.row]
                    switch address_item {
                    case .addresses:
                        var needsShow : Bool = false
                        let alertController = UIAlertController(title: LocalString._settings_change_default_address_to, message: nil, preferredStyle: .actionSheet)
                        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
                        let defaultAddress : Address? = multi_domains.defaultAddress()
                        for addr in multi_domains {
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
                                        for oldAddr in self.multi_domains {
                                            if oldAddr != addr {
                                                newAddrs.append(oldAddr)
                                                newOrder.append(oldAddr.address_id)
                                                oldAddr.order = order
                                                order += 1
                                            }
                                        }
                                        let view = UIApplication.shared.keyWindow
                                        ActivityIndicatorHelper.show(at: view)
                                        sharedUserDataService.updateUserDomiansOrder(newAddrs,  newOrder:newOrder) { _, _, error in
                                            tableView.reloadData()
                                            ActivityIndicatorHelper.hide(at: view)
                                            if error == nil {
                                                self.multi_domains = newAddrs
                                                tableView.reloadData()
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
                        self.performSegue(withIdentifier: DisplayNameSegue, sender: self)
                    case .signature:
                        self.performSegue(withIdentifier: SignatureSegue, sender: self)
                    case .defaultMobilSign:
                        self.performSegue(withIdentifier: MobileSignatureSegue, sender: self)
                    }
                }
            case .swipeAction:
                if setting_swipe_action_items.count > indexPath.row {
                    let action_item = setting_swipe_action_items[indexPath.row]
                    let alertController = UIAlertController(title: action_item.actionDescription, message: nil, preferredStyle: .actionSheet)
                    alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
                    
                    let currentAction = action_item == .left ? sharedUserDataService.swiftLeft : sharedUserDataService.swiftRight
                    for swipeAction in setting_swipe_actions {
                        if swipeAction != currentAction {
                            alertController.addAction(UIAlertAction(title: swipeAction.description, style: .default, handler: { (action) -> Void in
                                let _ = self.navigationController?.popViewController(animated: true)
                                let view = UIApplication.shared.keyWindow
                                ActivityIndicatorHelper.show(at: view)
                                sharedUserDataService.updateUserSwipeAction(action_item == .left, action: swipeAction, completion: { (task, response, error) -> Void in
                                    tableView.reloadData()
                                    ActivityIndicatorHelper.hide(at: view)
                                    if error == nil {
                                        tableView.reloadData()
                                    }
                                })
                            }))
                        }
                    }
                    let cell = tableView.cellForRow(at: indexPath)
                    alertController.popoverPresentationController?.sourceView = cell ?? self.view
                    alertController.popoverPresentationController?.sourceRect = (cell == nil ? self.view.frame : cell!.bounds)
                    present(alertController, animated: true, completion: nil)
                }
            case .labels:
                self.performSegue(withIdentifier: kManagerLabelsSegue, sender: self)
            case .language:
                let current_language = LanguageManager.currentLanguageEnum()
                let title = LocalString._settings_current_language_is + current_language.description
                let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
                alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
                for l in setting_languages {
                    if l != current_language {
                        alertController.addAction(UIAlertAction(title: l.description, style: .default, handler: { (action) -> Void in
                            let _ = self.navigationController?.popViewController(animated: true)
                            LanguageManager.saveLanguage(byCode: l.code)
                            LocalizedString.reset()
                            
                            self.updateTitle()
                            tableView.reloadData()
                        }))
                    }
                }
                let cell = tableView.cellForRow(at: indexPath)
                alertController.popoverPresentationController?.sourceView = cell ?? self.view
                alertController.popoverPresentationController?.sourceRect = (cell == nil ? self.view.frame : cell!.bounds)
                present(alertController, animated: true, completion: nil)
            default:
                break
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // Override to support conditional editing of the table view.
    @objc func tableView(_ tableView: UITableView, canEditRowAtIndexPath indexPath: IndexPath) -> Bool {
        return false
    }
    
    // Override to support conditional rearranging of the table view.
    @objc func tableView(_ tableView: UITableView, canMoveRowAtIndexPath indexPath: IndexPath) -> Bool {
        return false
    }
    
    // Override to support editing the table view.
    @objc func tableView(_ tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: IndexPath) {
    }
    
    @objc func tableView(_ tableView: UITableView, editingStyleForRowAtIndexPath indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.none
    }
    
    @objc func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: IndexPath) -> Bool {
        return false
    }
    
    @objc func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAtIndexPath sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if sourceIndexPath.section != proposedDestinationIndexPath.section {
            return sourceIndexPath
        }
        else {
            return proposedDestinationIndexPath
        }
    }
    
    // Override to support rearranging the table view.
    @objc func tableView(_ tableView: UITableView, moveRowAtIndexPath fromIndexPath: IndexPath, toIndexPath: IndexPath) {
        if setting_headers[fromIndexPath.section] == SettingSections.multiDomain {
            let val = self.multi_domains.remove(at: fromIndexPath.row)
            self.multi_domains.insert(val, at: toIndexPath.row)
            //let indexSet = NSIndexSet(index:fromIndexPath.section)
            tableView.reloadData()
        }
    }
    
}
