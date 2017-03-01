//
//  SettingTableViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/17/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit
import LocalAuthentication

class SettingTableViewController: ProtonMailViewController {
    
    var setting_headers : [SettingSections] = [.General, .Protection, .Labels, .MultiDomain, .SwipeAction, .Storage, .Version] //SettingSections.Debug,
    var setting_general_items : [SGItems] = [.NotifyEmail, .LoginPWD, .MBP, .AutoLoadImage, .CleanCache]
    var setting_debug_items : [SDebugItem] = [.Queue, .ErrorLogs]
    
    var setting_swipe_action_items : [SSwipeActionItems] = [.left, .right]
    var setting_swipe_actions : [MessageSwipeAction] = [.trash, .spam, .star, .archive]
    
    var setting_protection_items : [SProtectionItems] = [.TouchID, .PinCode] // [.TouchID, .PinCode, .UpdatePin, .AutoLogout, .EnterTime]
    var setting_addresses_items : [SAddressItems] = [.Addresses, .DisplayName, .Signature, .DefaultMobilSign]
    
    var setting_labels_items : [SLabelsItems] = [.LabelManager, .FolderManager]
    
    var protection_auto_logout : [Int] = [-1, 0, 1, 2, 5, 10, 15, 30, 60]
    
    var multi_domains: Array<Address>!
    var userInfo = sharedUserDataService.userInfo
    
    /// segues
    let NotificationSegue:String = "setting_notification"
    let DisplayNameSegue:String = "setting_displayname"
    let SignatureSegue:String = "setting_signature"
    let MobileSignatureSegue:String = "setting_mobile_signature"
    let DebugQueueSegue : String = "setting_debug_queue_segue"
    let kSetupPinCodeSegue : String = "setting_setup_pingcode"
    let kManagerLabelsSegue : String = "toManagerLabelsSegue"
    let kLoginpwdSegue:String = "setting_login_pwd"
    let kMailboxpwdSegue:String = "setting_mailbox_pwd"
    let kSinglePasswordSegue : String = "setting_single_password_segue"
    /// cells
    let SettingSingalLineCell = "settings_general"
    let SettingTwoLinesCell = "settings_twolines"
    let SettingDomainsCell = "setting_domains"
    let SettingStorageCell = "setting_storage_cell"
    let HeaderCell = "header_cell"
    let SingleTextCell = "single_text_cell"
    let SwitchCell = "switch_table_view_cell"
    let kTouchIDCell = "touch_id_switch_table_cell"
    
    //
    let CellHeight : CGFloat = 30.0
    
    var cleaning : Bool = false
    
    //
    @IBOutlet weak var editBarButton: UIBarButtonItem!
    @IBOutlet var settingTableView: UITableView!
    
    //
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if userCachedStatus.isPinCodeEnabled || userCachedStatus.isTouchIDEnabled {
            setting_protection_items = [.TouchID, .PinCode, .EnterTime]
        }
        
        if sharedUserDataService.passwordMode == 1 {
            setting_general_items = [.NotifyEmail, .SinglePWD, .AutoLoadImage, .CleanCache]
        } else {
            setting_general_items = [.NotifyEmail, .LoginPWD, .MBP, .AutoLoadImage, .CleanCache]
        }
        
        userInfo = sharedUserDataService.userInfo
        multi_domains = sharedUserDataService.userAddresses
        UIView.setAnimationsEnabled(false)
        settingTableView.reloadData()
        UIView.setAnimationsEnabled(true)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let segueID:String! = segue.identifier
        switch segueID
        {
        case kLoginpwdSegue:
            let changeLoginPwdView = segue.destinationViewController as! ChangePasswordViewController
            changeLoginPwdView.setViewModel(shareViewModelFactoy.getChangeLoginPassword())
        case kMailboxpwdSegue:
            let changeMBPView = segue.destinationViewController as! ChangePasswordViewController
            changeMBPView.setViewModel(shareViewModelFactoy.getChangeMailboxPassword())
        case kSinglePasswordSegue:
            let changeMBPView = segue.destinationViewController as! ChangePasswordViewController
            changeMBPView.setViewModel(shareViewModelFactoy.getChangeSinglePassword())
        case NotificationSegue:
            let changeMBPView = segue.destinationViewController as! SettingDetailViewController
            changeMBPView.setViewModel(shareViewModelFactoy.getChangeNotificationEmail())
        case DisplayNameSegue:
            let changeMBPView = segue.destinationViewController as! SettingDetailViewController
            changeMBPView.setViewModel(shareViewModelFactoy.getChangeDisplayName())
        case SignatureSegue:
            let changeMBPView = segue.destinationViewController as! SettingDetailViewController
            changeMBPView.setViewModel(shareViewModelFactoy.getChangeSignature())
        case MobileSignatureSegue:
            let changeMBPView = segue.destinationViewController as! SettingDetailViewController
            changeMBPView.setViewModel(shareViewModelFactoy.getChangeMobileSignature())
        case kSetupPinCodeSegue:
            let vc = segue.destinationViewController as! PinCodeViewController
            vc.viewModel = SetPinCodeModelImpl()
        case kManagerLabelsSegue:
            let vc = segue.destinationViewController as! LablesViewController
            vc.viewModel = LabelManagerViewModelImpl()
            self.setPresentationStyleForSelfController(self, presentingController: vc)
        default:
            break
        }
    }
    
    internal func updateTableProtectionSection() {
        if userCachedStatus.isPinCodeEnabled || userCachedStatus.isTouchIDEnabled {
            setting_protection_items = [.TouchID, .PinCode, .EnterTime]
        } else {
            setting_protection_items = [.TouchID, .PinCode]
        }
        self.settingTableView.reloadData()
    }
    
    // MARK: - Table view data source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return setting_headers.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if setting_headers.count > section {
            switch(setting_headers[section])
            {
            case .Debug:
                return setting_debug_items.count
            case .General:
                return setting_general_items.count
            case .MultiDomain:
                return setting_addresses_items.count
            case .SwipeAction:
                return setting_swipe_action_items.count
            case .Storage:
                return 1
            case .Version:
                return 0
            case .Protection:
                return setting_protection_items.count
            case .Language:
                return 0
            case .Labels:
                return setting_labels_items.count
            }
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cellout : UITableViewCell?
        if setting_headers.count > indexPath.section {
            let setting_item = setting_headers[indexPath.section]
            switch setting_item {
            case .General:
                if setting_general_items.count > indexPath.row {
                    let itme: SGItems = setting_general_items[indexPath.row]
                    switch itme {
                    case .NotifyEmail:
                        let cell = tableView.dequeueReusableCellWithIdentifier(SettingTwoLinesCell, forIndexPath: indexPath) as! SettingsCell
                        cell.LeftText.text = itme.description
                        cell.RightText.text = userInfo?.notificationEmail
                        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                        cellout = cell
                    case .LoginPWD, .MBP, .SinglePWD:
                        let cell = tableView.dequeueReusableCellWithIdentifier(SettingTwoLinesCell, forIndexPath: indexPath) as! SettingsCell
                        cell.LeftText.text = itme.description
                        cell.RightText.text = NSLocalizedString("**********")
                        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                        cellout = cell
                    case .CleanCache:
                        let cell = tableView.dequeueReusableCellWithIdentifier(SettingSingalLineCell, forIndexPath: indexPath) as! GeneralSettingViewCell
                        cell.configCell(itme.description, right: "")
                        cell.accessoryType = UITableViewCellAccessoryType.None
                        cellout = cell
                    case .AutoLoadImage:
                        let cell = tableView.dequeueReusableCellWithIdentifier(SwitchCell, forIndexPath: indexPath) as! SwitchTableViewCell
                        cell.accessoryType = UITableViewCellAccessoryType.None
                        cell.selectionStyle = UITableViewCellSelectionStyle.None
                        cell.configCell(itme.description, bottomLine: "", status: !sharedUserDataService.showShowImageView, complete: { (cell, newStatus, feedback) -> Void in
                            if let indexp = tableView.indexPathForCell(cell) {
                                if indexPath == indexp {
                                    let window : UIWindow = UIApplication.sharedApplication().windows.last as UIWindow!
                                    ActivityIndicatorHelper.showActivityIndicatorAtView(window)
                                    sharedUserDataService.updateAutoLoadImage(newStatus == true ? 1 : 0) { _, _, error in
                                        ActivityIndicatorHelper.hideActivityIndicatorAtView(window)
                                        if let error = error {
                                            feedback(isOK: false)
                                            let alertController = error.alertController()
                                            alertController.addOKAction()
                                            self.presentViewController(alertController, animated: true, completion: nil)
                                        } else {
                                            feedback(isOK: true)
                                        }
                                    }
                                } else {
                                    feedback(isOK: false)
                                }
                            } else {
                                feedback(isOK: false)
                            }
                        })
                        cellout = cell
                    }
                }
            case .Protection:
                if setting_protection_items.count > indexPath.row {
                    let item : SProtectionItems = setting_protection_items[indexPath.row]
                    switch item {
                    case .TouchID:
                        let cell = tableView.dequeueReusableCellWithIdentifier(SwitchCell, forIndexPath: indexPath) as! SwitchTableViewCell
                        cell.accessoryType = UITableViewCellAccessoryType.None
                        cell.selectionStyle = UITableViewCellSelectionStyle.None
                        cell.configCell(item.description, bottomLine: "", status: userCachedStatus.isTouchIDEnabled, complete: { (cell, newStatus, feedback) -> Void in
                            if let indexp = tableView.indexPathForCell(cell) {
                                if indexPath == indexp {
                                    if !userCachedStatus.isTouchIDEnabled {
                                        // try to enable touch id
                                        let context = LAContext()
                                        // Declare a NSError variable.
                                        var error: NSError?
                                        // Check if the device can evaluate the policy.
                                        if context.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: &error) {
                                            userCachedStatus.isTouchIDEnabled = true
                                            userCachedStatus.touchIDEmail = sharedUserDataService.username ?? ""
                                            self.updateTableProtectionSection()
                                        }
                                        else{
                                            var alertString : String = ""
                                            // If the security policy cannot be evaluated then show a short message depending on the error.
                                            switch error!.code{
                                            case LAError.TouchIDNotEnrolled.rawValue:
                                                alertString = "TouchID is not enrolled, enable it in the system Settings"
                                            case LAError.PasscodeNotSet.rawValue:
                                                alertString = "A passcode has not been set, enable it in the system Settings"
                                            default:
                                                // The LAError.TouchIDNotAvailable case.
                                                alertString = "TouchID not available"
                                            }
                                            PMLog.D(alertString)
                                            PMLog.D("\(error?.localizedDescription)")
                                            alertString.alertToast()
                                            feedback(isOK: false)
                                        }
                                    } else {
                                        userCachedStatus.isTouchIDEnabled = false
                                        userCachedStatus.touchIDEmail = ""
                                        self.updateTableProtectionSection()
                                    }
                                } else {
                                    feedback(isOK: false)
                                }
                            } else {
                                feedback(isOK: false)
                            }
                        })
                        cellout = cell
                    case .PinCode:
                        let cell = tableView.dequeueReusableCellWithIdentifier(SwitchCell, forIndexPath: indexPath) as! SwitchTableViewCell
                        cell.accessoryType = UITableViewCellAccessoryType.None
                        cell.selectionStyle = UITableViewCellSelectionStyle.None
                        cell.configCell(item.description, bottomLine: "", status: userCachedStatus.isPinCodeEnabled, complete: { (cell, newStatus, feedback) -> Void in
                            if let indexp = tableView.indexPathForCell(cell) {
                                if indexPath == indexp {
                                    if !userCachedStatus.isPinCodeEnabled {
                                        self.performSegueWithIdentifier(self.kSetupPinCodeSegue, sender: self)
                                    } else {
                                        userCachedStatus.isPinCodeEnabled = false
                                        feedback(isOK: true)
                                        self.updateTableProtectionSection()
                                    }
                                } else {
                                    feedback(isOK: false)
                                }
                            } else {
                                feedback(isOK: false)
                            }
                        })
                        cellout = cell
                    case .UpdatePin:
                        let cell = tableView.dequeueReusableCellWithIdentifier(SettingSingalLineCell, forIndexPath: indexPath) as! GeneralSettingViewCell
                        cell.configCell(item.description, right: "")
                        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                        cellout = cell
                    case .AutoLogout:
                        let cell = tableView.dequeueReusableCellWithIdentifier(SwitchCell, forIndexPath: indexPath) as! SwitchTableViewCell
                        cell.accessoryType = UITableViewCellAccessoryType.None
                        cell.selectionStyle = UITableViewCellSelectionStyle.None
                        cell.configCell(item.description, bottomLine: "", status: userCachedStatus.isPinCodeEnabled, complete: { (cell, newStatus, feedback) -> Void in
                            if let indexp = tableView.indexPathForCell(cell) {
                                if indexPath == indexp {
                                    
                                } else {
                                    feedback(isOK: false)
                                }
                            } else {
                                feedback(isOK: false)
                            }
                        })
                        cellout = cell
                    case .EnterTime:
                        var timeIndex : Int = -1
                        if let t = Int(userCachedStatus.lockTime) {
                            timeIndex = t
                        }
                        
                        var text = "\(timeIndex) Minutes"
                        if timeIndex == -1 {
                            text = "None"
                        } else if timeIndex == 0 {
                            text = "Every time enter app"
                        } else if timeIndex == 1{
                            text = "\(timeIndex) Minute"
                        }
                        
                        let cell = tableView.dequeueReusableCellWithIdentifier(SettingTwoLinesCell, forIndexPath: indexPath) as! SettingsCell
                        cell.LeftText.text = item.description
                        cell.RightText.text = text
                        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                        cellout = cell
                    }
                }
            case .Labels:
                if setting_labels_items.count > indexPath.row {
                    let label_item = setting_labels_items[indexPath.row]
                    let cell = tableView.dequeueReusableCellWithIdentifier(SettingSingalLineCell, forIndexPath: indexPath) as! GeneralSettingViewCell
                    cell.configCell(label_item.description, right: "")
                    cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                    cellout = cell
                }
            case .MultiDomain:
                if setting_addresses_items.count > indexPath.row {
                    let address_item: SAddressItems = setting_addresses_items[indexPath.row]
                    switch address_item {
                    case .Addresses:
                        let cell = tableView.dequeueReusableCellWithIdentifier(SettingDomainsCell, forIndexPath: indexPath) as! DomainsTableViewCell
                        if let addr = multi_domains.getDefaultAddress() {
                            cell.domainText.text = addr.email
                        } else {
                            cell.domainText.text = NSLocalizedString("Unknown")
                        }
                        cell.defaultMark.text = NSLocalizedString("Default")
                        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                        cellout = cell
                    case .DisplayName:
                        let cell = tableView.dequeueReusableCellWithIdentifier(SettingTwoLinesCell, forIndexPath: indexPath) as! SettingsCell
                        cell.LeftText.text = address_item.description
                        if let addr = sharedUserDataService.userAddresses.getDefaultAddress() {
                            cell.RightText.text = addr.display_name
                        } else {
                            cell.RightText.text = sharedUserDataService.displayName
                        }
                        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                        cellout = cell
                    case .Signature:
                        let cell = tableView.dequeueReusableCellWithIdentifier(SettingSingalLineCell, forIndexPath: indexPath) as! GeneralSettingViewCell
                        cell.configCell(address_item.description, right: "")
                        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                        cellout = cell
                    case .DefaultMobilSign:
                        let cell = tableView.dequeueReusableCellWithIdentifier(SettingSingalLineCell, forIndexPath: indexPath) as! GeneralSettingViewCell
                        cell.configCell(address_item.description, right: "")
                        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                        cellout = cell
                    }
                }
            case .SwipeAction:
                if indexPath.row < setting_swipe_action_items.count {
                    let actionItem = setting_swipe_action_items[indexPath.row]
                    let cell = tableView.dequeueReusableCellWithIdentifier(SettingDomainsCell, forIndexPath: indexPath) as! DomainsTableViewCell
                    let action = actionItem == .left ? sharedUserDataService.swiftLeft : sharedUserDataService.swiftRight
                    cell.domainText.text = actionItem.description
                    cell.defaultMark.text = action.description
                    cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                    cellout = cell
                }
            case .Storage:
                let cell = tableView.dequeueReusableCellWithIdentifier(SettingStorageCell, forIndexPath: indexPath) as! StorageViewCell
                let usedSpace = sharedUserDataService.usedSpace
                let maxSpace = sharedUserDataService.maxSpace
                cell.setValue(usedSpace, maxSpace: maxSpace)
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                cellout = cell
            case .Debug:
                if  setting_debug_items.count > indexPath.row {
                    let itme: SDebugItem = setting_debug_items[indexPath.row]
                    let cell = tableView.dequeueReusableCellWithIdentifier(SettingTwoLinesCell, forIndexPath: indexPath) as! GeneralSettingViewCell
                    cell.LeftText.text = itme.description
                    cell.RightText.text  = ""
                    cellout = cell
                }
            case .Version, .Language:
                break
            }
        }
        
        if let cellout = cellout {
            return cellout
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(SettingSingalLineCell, forIndexPath: indexPath) as! GeneralSettingViewCell
            cell.configCell("", right: "")
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            return cell
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerCell = tableView.dequeueReusableCellWithIdentifier(HeaderCell) as! CustomHeaderView
        if(setting_headers[section] == SettingSections.Version){
            var appVersion = "Unkonw Version"
            var libVersion = "| LibVersion: 1.0.0"
            
            if let version = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String {
                appVersion = "AppVersion: \(version)"
            }
            if let build = NSBundle.mainBundle().infoDictionary?["CFBundleVersion"] as? String {
                appVersion = appVersion.stringByAppendingString(" (\(build))")
            }
            
            let lib_v = PMNLibVersion.getLibVersion()
            libVersion = "| LibVersion: \(lib_v)"
            headerCell.headerText.text = NSLocalizedString(appVersion + " " + libVersion)
        }
        else
        {
            headerCell.headerText.text = setting_headers[section].description
        }
        return headerCell
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return CellHeight
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if setting_headers.count > indexPath.section {
            let setting_item = setting_headers[indexPath.section]
            switch setting_item {
            case .General:
                if setting_general_items.count > indexPath.row {
                    let general_itme: SGItems = setting_general_items[indexPath.row]
                    switch general_itme {
                    case .NotifyEmail:
                        self.performSegueWithIdentifier(NotificationSegue, sender: self)
                    case .LoginPWD:
                       // if shard
                        if sharedUserDataService.passwordMode == 1 {
                            let alert = NSLocalizedString("Please use the web version of ProtonMail to change your passwords.!").alertController()
                            alert.addOKAction()
                            presentViewController(alert, animated: true, completion: nil)
                        } else {
                            self.performSegueWithIdentifier(kLoginpwdSegue, sender: self)
                        }
                    case .MBP:
                        self.performSegueWithIdentifier(kMailboxpwdSegue, sender: self)
                    case .SinglePWD:
                        self.performSegueWithIdentifier(kSinglePasswordSegue, sender: self)
                    case .CleanCache:
                        if !cleaning {
                            cleaning = true
                            let window : UIWindow = UIApplication.sharedApplication().windows.last as UIWindow!
                            let hud : MBProgressHUD = MBProgressHUD.showHUDAddedTo(window, animated: true)
                            hud.labelText = NSLocalizedString("Resetting message cache ...")
                            hud.removeFromSuperViewOnHide = true
                            sharedMessageDataService.cleanLocalMessageCache() { task, res, error in
                                hud.mode = MBProgressHUDMode.Text
                                hud.labelText = NSLocalizedString("Done")
                                hud.hide(true, afterDelay: 1)
                                self.cleaning = false
                            }
                        }
                    case .AutoLoadImage:
                        break
                    }
                }
            case .Debug:
                if setting_debug_items.count > indexPath.row {
                    let debug_item: SDebugItem = setting_debug_items[indexPath.row]
                    switch debug_item {
                    case .Queue:
                        self.performSegueWithIdentifier(DebugQueueSegue, sender: self)
                        break
                    case .ErrorLogs:
                        break
                    }
                }
            case .Protection:
                if setting_protection_items.count > indexPath.row {
                    let protection_item: SProtectionItems = setting_protection_items[indexPath.row]
                    switch protection_item {
                    case .TouchID:
                        break
                    case .PinCode:
                        break
                    case .UpdatePin:
                        break
                    case .AutoLogout:
                        break
                    case .EnterTime:
                        let alertController = UIAlertController(title: NSLocalizedString("Auto Lock Time"), message: nil, preferredStyle: .ActionSheet)
                        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .Cancel, handler: nil))
                        for timeIndex in protection_auto_logout {
                            var text = "\(timeIndex) Minutes"
                            if timeIndex == -1 {
                                text = "None"
                            } else if timeIndex == 0 {
                                text = "Every time enter app"
                            } else if timeIndex == 1{
                                text = "\(timeIndex) Minute"
                            }
                            alertController.addAction(UIAlertAction(title: text, style: .Default, handler: { (action) -> Void in
                                self.navigationController?.popViewControllerAnimated(true)
                                userCachedStatus.lockTime = "\(timeIndex)"
                                tableView.reloadData()
                            }))
                        }
                        let cell = tableView.cellForRowAtIndexPath(indexPath)
                        alertController.popoverPresentationController?.sourceView = cell ?? self.view
                        alertController.popoverPresentationController?.sourceRect = (cell == nil ? self.view.frame : cell!.bounds)
                        presentViewController(alertController, animated: true, completion: nil)
                    }
                }
            case .MultiDomain:
                if setting_addresses_items.count > indexPath.row {
                    let address_item: SAddressItems = setting_addresses_items[indexPath.row]
                    switch address_item {
                    case .Addresses:
                        var needsShow : Bool = false
                        let alertController = UIAlertController(title: NSLocalizedString("Change default address to .."), message: nil, preferredStyle: .ActionSheet)
                        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .Cancel, handler: nil))
                        let defaultAddress : Address? = multi_domains.getDefaultAddress()
                        for addr in multi_domains {
                            if addr.status == 1 && addr.receive == 1 {
                                if defaultAddress != addr {
                                    needsShow = true
                                    alertController.addAction(UIAlertAction(title: addr.email, style: .Default, handler: { (action) -> Void in
                                        self.navigationController?.popViewControllerAnimated(true)
                                        var newAddrs = Array<Address>()
                                        var newOrder = Array<Int>()
                                        newAddrs.append(addr)
                                        newOrder.append(addr.send)
                                        var order = 1
                                        addr.send = order
                                        order += 1
                                        for oldAddr in self.multi_domains {
                                            if oldAddr != addr {
                                                newAddrs.append(oldAddr)
                                                newOrder.append(oldAddr.send)
                                                oldAddr.send = order
                                                order += 1
                                            }
                                        }
                                        let window : UIWindow = UIApplication.sharedApplication().windows.last as UIWindow!
                                        ActivityIndicatorHelper.showActivityIndicatorAtView(window)
                                        sharedUserDataService.updateUserDomiansOrder(newAddrs,  newOrder:newOrder) { _, _, error in
                                            tableView.reloadData()
                                            ActivityIndicatorHelper.hideActivityIndicatorAtView(window)
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
                            let cell = tableView.cellForRowAtIndexPath(indexPath)
                            alertController.popoverPresentationController?.sourceView = cell ?? self.view
                            alertController.popoverPresentationController?.sourceRect = (cell == nil ? self.view.frame : cell!.bounds)
                            presentViewController(alertController, animated: true, completion: nil)
                        }
                    case .DisplayName:
                        self.performSegueWithIdentifier(DisplayNameSegue, sender: self)
                    case .Signature:
                        self.performSegueWithIdentifier(SignatureSegue, sender: self)
                    case .DefaultMobilSign:
                        self.performSegueWithIdentifier(MobileSignatureSegue, sender: self)
                    }
                }
            case .SwipeAction:
                if setting_swipe_action_items.count > indexPath.row {
                    let action_item = setting_swipe_action_items[indexPath.row]
                    let alertController = UIAlertController(title: action_item.actionDescription, message: nil, preferredStyle: .ActionSheet)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .Cancel, handler: nil))
                    
                    let currentAction = action_item == .left ? sharedUserDataService.swiftLeft : sharedUserDataService.swiftRight
                    for swipeAction in setting_swipe_actions {
                        if swipeAction != currentAction {
                            alertController.addAction(UIAlertAction(title: swipeAction.description, style: .Default, handler: { (action) -> Void in
                                self.navigationController?.popViewControllerAnimated(true)
                                let window : UIWindow = UIApplication.sharedApplication().windows.last as UIWindow!
                                ActivityIndicatorHelper.showActivityIndicatorAtView(window)
                                sharedUserDataService.updateUserSwipeAction(action_item == .left, action: swipeAction, completion: { (task, response, error) -> Void in
                                    tableView.reloadData()
                                    ActivityIndicatorHelper.hideActivityIndicatorAtView(window)
                                    if error == nil {
                                        tableView.reloadData()
                                    }
                                })
                            }))
                        }
                    }
                    let cell = tableView.cellForRowAtIndexPath(indexPath)
                    alertController.popoverPresentationController?.sourceView = cell ?? self.view
                    alertController.popoverPresentationController?.sourceRect = (cell == nil ? self.view.frame : cell!.bounds)
                    presentViewController(alertController, animated: true, completion: nil)
                }
            case .Labels:
                self.performSegueWithIdentifier(kManagerLabelsSegue, sender: self)
            default:
                break
            }
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // Override to support conditional editing of the table view.
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    // Override to support conditional rearranging of the table view.
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    // Override to support editing the table view.
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.None
    }
    
    func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    func tableView(tableView: UITableView, targetIndexPathForMoveFromRowAtIndexPath sourceIndexPath: NSIndexPath, toProposedIndexPath proposedDestinationIndexPath: NSIndexPath) -> NSIndexPath {
        if sourceIndexPath.section != proposedDestinationIndexPath.section {
            return sourceIndexPath
        }
        else {
            return proposedDestinationIndexPath
        }
    }
    
    // Override to support rearranging the table view.
    func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        if setting_headers[fromIndexPath.section] == SettingSections.MultiDomain {
            let val = self.multi_domains.removeAtIndex(fromIndexPath.row)
            self.multi_domains.insert(val, atIndex: toIndexPath.row)
            //let indexSet = NSIndexSet(index:fromIndexPath.section)
            tableView.reloadData()
        }
    }
    
}

extension SettingTableViewController {
    
    enum SDebugItem: Int, CustomStringConvertible {
        case Queue = 0
        case ErrorLogs = 1
        var description : String {
            switch(self){
            case Queue:
                return NSLocalizedString("Message Queue")
            case ErrorLogs:
                return NSLocalizedString("Error Logs")
            }
        }
    }
    
    enum SGItems: Int, CustomStringConvertible {
        case NotifyEmail = 0
        //        case DisplayName = 1
        //        case Signature = 2
        case LoginPWD = 3
        case MBP = 4
        case CleanCache = 5
        case AutoLoadImage = 9
        case SinglePWD = 10
        
        var description : String {
            switch(self){
            case NotifyEmail:
                return NSLocalizedString("Notification Email")
            case LoginPWD:
                return NSLocalizedString("Login Password")
            case MBP:
                return NSLocalizedString("Mailbox Password")
            case SinglePWD:
                return NSLocalizedString("Single Password")
            case .CleanCache:
                return NSLocalizedString("Clear Local Message Cache")
            case .AutoLoadImage:
                return NSLocalizedString("Auto Show Images")
            }
        }
    }
    
    enum SSwipeActionItems: Int, CustomStringConvertible {
        case left = 0
        case right = 1
        
        var description : String {
            switch(self){
            case left:
                return NSLocalizedString("Swipe Left to Right")
            case right:
                return NSLocalizedString("Swipe Right to Left")
            }
        }
        
        var actionDescription : String {
            switch(self){
            case left:
                return NSLocalizedString("Change left swipe action")
            case right:
                return NSLocalizedString("Change right swipe action")
            }
        }
    }
    
    enum SProtectionItems : Int, CustomStringConvertible {
        case TouchID = 0
        case PinCode = 1
        case UpdatePin = 2
        case AutoLogout = 3
        case EnterTime = 4
        
        var description : String {
            switch(self){
            case TouchID:
                return NSLocalizedString("Enable TouchID")
            case PinCode:
                return NSLocalizedString("Enable Pin Protection")
            case UpdatePin:
                return NSLocalizedString("Change Pin")
            case AutoLogout:
                return NSLocalizedString("Protection Entire App")
            case EnterTime:
                return NSLocalizedString("Auto Lock Time")
            }
        }
    }
    
    enum SAddressItems: Int, CustomStringConvertible {
        case Addresses = 0
        case DisplayName = 1
        case Signature = 2
        case DefaultMobilSign = 3
        
        var description : String {
            switch(self){
            case Addresses:
                return NSLocalizedString("")
            case DisplayName:
                return NSLocalizedString("Display Name")
            case Signature:
                return NSLocalizedString("Signature")
            case DefaultMobilSign:
                return NSLocalizedString("Mobile Signature")
            }
        }
    }
    
    enum SLabelsItems: Int, CustomStringConvertible {
        case LabelManager = 0
        case FolderManager = 1
        var description : String {
            switch(self){
            case LabelManager:
                return NSLocalizedString("Manage Labels")
            case .FolderManager:
                return NSLocalizedString("Manage Folders")
            }
        }
    }
    
    enum SettingSections: Int, CustomStringConvertible {
        case Debug = 0
        case General = 1
        case MultiDomain = 2
        case Storage = 3
        case Version = 4
        case SwipeAction = 5
        case Protection = 6
        case Language = 7
        case Labels = 8
        
        var description : String {
            switch(self){
            case Debug:
                return NSLocalizedString("Debug")
            case General:
                return NSLocalizedString("General Settings")
            case MultiDomain:
                return NSLocalizedString("Multiple Addresses")
            case Storage:
                return NSLocalizedString("Storage")
            case Version:
                return NSLocalizedString("")
            case SwipeAction:
                return NSLocalizedString("Message Swipe Actions")
            case Protection:
                return NSLocalizedString("Protection")
            case Language:
                return NSLocalizedString("Language")
            case Labels:
                return NSLocalizedString("Labels Manager")
            }
        }
    }
}
