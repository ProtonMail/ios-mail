//
//  SettingTableViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/17/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

class SettingTableViewController: ProtonMailViewController {
    
    var setting_headers = [SettingSections.General, SettingSections.MultiDomain, SettingSections.SwipeAction, SettingSections.Storage, SettingSections.Version] //SettingSections.Debug,
    var setting_general_items = [SGItems.NotifyEmail, SGItems.DisplayName, SGItems.Signature, SGItems.LoginPWD, SGItems.CleanCache, SGItems.DefaultMobilSign]  //SGItems.MBP,
    var setting_debug_items = [SDebugItem.Queue, SDebugItem.ErrorLogs, SDebugItem.CleanCache]
    
    var setting_swipe_action_items = [SSwipeActionItems.left, SSwipeActionItems.right]
    var setting_swipe_actions = [MessageSwipeAction.trash, MessageSwipeAction.spam, MessageSwipeAction.star, MessageSwipeAction.archive]
    
    var multi_domains: Array<Address>!
    var userInfo = sharedUserDataService.userInfo
    
    /// segues
    let NotificationSegue:String = "setting_notification"
    let DisplayNameSegue:String = "setting_displayname"
    let SignatureSegue:String = "setting_signature"
    let LoginpwdSegue:String = "setting_login_pwd"
    let MailboxpwdSegue:String = "setting_mailbox_pwd"
    
    let DebugQueueSegue : String = "setting_debug_queue_segue"
    
    
    /// cells
    let SettingGeneralCell = "settings_twolines"
    let SettingDomainsCell = "setting_domains"
    let SettingStorageCell = "setting_storage_cell"
    let HeaderCell = "header_cell"
    let SingleTextCell = "single_text_cell"
    let SwitchCell = "switch_table_view_cell"
    
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
        userInfo = sharedUserDataService.userInfo
        multi_domains = sharedUserDataService.userAddresses
        UIView.setAnimationsEnabled(false)
        settingTableView.reloadData();
        UIView.setAnimationsEnabled(true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let segueID:String! = segue.identifier
        switch segueID
        {
        case LoginpwdSegue:
            let changeLoginPwdView = segue.destinationViewController as! ChangePasswordViewController;
            changeLoginPwdView.setViewModel(shareViewModelFactoy.getChangeLoginPassword())
            break
        case MailboxpwdSegue:
            let changeMBPView = segue.destinationViewController as! ChangePasswordViewController;
            changeMBPView.setViewModel(shareViewModelFactoy.getChangeMailboxPassword())
            break
        case NotificationSegue:
            let changeMBPView = segue.destinationViewController as! SettingDetailViewController;
            changeMBPView.setViewModel(shareViewModelFactoy.getChangeNotificationEmail())
            break
        case DisplayNameSegue:
            let changeMBPView = segue.destinationViewController as! SettingDetailViewController;
            changeMBPView.setViewModel(shareViewModelFactoy.getChangeDisplayName())
            break
        case SignatureSegue:
            let changeMBPView = segue.destinationViewController as! SettingDetailViewController;
            changeMBPView.setViewModel(shareViewModelFactoy.getChangeSignature())
            break
        default:
            break
        }
    }
    
    // MARK: - button acitons
    @IBAction func editAction(sender: AnyObject) {
        settingTableView.setEditing(!settingTableView.editing, animated: true)
        if settingTableView.editing
        {
            editBarButton.title = NSLocalizedString("Done")
        }
        else
        {
            //            ActivityIndicatorHelper.showActivityIndicatorAtView(view)
            //            editBarButton.title = NSLocalizedString("Edit")
            //            sharedUserDataService.updateUserDomiansOrder(multi_domains) { _, _, error in
            //                ActivityIndicatorHelper.hideActivityIndicatorAtView(self.view)
            //                if let error = error {
            //                } else {
            //                }
            //            }
        }
    }
    
    // MARK: - Table view data source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return setting_headers.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch(setting_headers[section])
        {
        case .Debug:
            return setting_debug_items.count
        case .General:
            return setting_general_items.count
        case .MultiDomain:
            return 1
        case .SwipeAction:
            return setting_swipe_action_items.count
        case .Storage:
            return 1
        case .Version:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if setting_headers.count > indexPath.section {
            if setting_headers[indexPath.section] == .General {
                var cellout : UITableViewCell!
                if setting_general_items.count > indexPath.row {
                    let itme: SGItems = setting_general_items[indexPath.row];
                    switch itme {
                    case SGItems.NotifyEmail:
                        let cell = tableView.dequeueReusableCellWithIdentifier(SettingGeneralCell, forIndexPath: indexPath) as! SettingsCell
                        cell.LeftText.text = itme.description;
                        cell.RightText.text = userInfo?.notificationEmail
                        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                        cellout = cell;
                        break;
                    case SGItems.DisplayName:
                        let cell = tableView.dequeueReusableCellWithIdentifier(SettingGeneralCell, forIndexPath: indexPath) as! SettingsCell
                        cell.LeftText.text = itme.description;
                        cell.RightText.text = sharedUserDataService.displayName
                        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                        cellout = cell;
                        break;
                    case SGItems.Signature:
                        let cell = tableView.dequeueReusableCellWithIdentifier(SettingGeneralCell, forIndexPath: indexPath) as! SettingsCell
                        cell.LeftText.text = itme.description;
                        cell.RightText.text = userInfo?.signature;
                        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                        cellout = cell;
                        break;
                    case SGItems.LoginPWD:
                        let cell = tableView.dequeueReusableCellWithIdentifier(SettingGeneralCell, forIndexPath: indexPath) as! SettingsCell
                        cell.LeftText.text = itme.description;
                        cell.RightText.text = "**********"
                        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                        cellout = cell;
                        break;
                    case SGItems.MBP:
                        let cell = tableView.dequeueReusableCellWithIdentifier(SettingGeneralCell, forIndexPath: indexPath) as! SettingsCell
                        cell.LeftText.text = itme.description;
                        cell.RightText.text = "**********"
                        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                        cellout = cell;
                        break;
                    case SGItems.CleanCache:
                        let cell = tableView.dequeueReusableCellWithIdentifier(SettingGeneralCell, forIndexPath: indexPath) as! SettingsCell
                        cell.LeftText.text = itme.description;
                        cell.RightText.text = ""
                        cell.accessoryType = UITableViewCellAccessoryType.None
                        cellout = cell;
                        break;
                    case SGItems.DefaultMobilSign:
                        let cell = tableView.dequeueReusableCellWithIdentifier(SwitchCell, forIndexPath: indexPath) as! SwitchTableViewCell
                        cell.accessoryType = UITableViewCellAccessoryType.None
                        let status = sharedUserDataService.switchCacheOff == false
                        cell.selectionStyle = UITableViewCellSelectionStyle.None
                        if sharedUserDataService.userInfo?.role > 0 {
                            cell.setUpSwitch(true, status: status)
                        } else {
                            cell.setUpSwitch(true, status: status) //was false
                        }
                        cellout = cell
                    }
                }
                return cellout
            }
            else if setting_headers[indexPath.section] == .MultiDomain {
                let cell = tableView.dequeueReusableCellWithIdentifier(SettingDomainsCell, forIndexPath: indexPath) as! DomainsTableViewCell
                
                for (var addr) in multi_domains {
                    if addr.status == 1 && addr.receive == 1 {
                        cell.domainText.text = addr.email
                        cell.defaultMark.text = NSLocalizedString("Default")
                        break
                    } else {
                        cell.domainText.text = "Unknown"
                        cell.defaultMark.text = NSLocalizedString("Default")
                    }
                }
                cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator;
                return cell
            }
            else if setting_headers[indexPath.section] == .SwipeAction {
                let cell = tableView.dequeueReusableCellWithIdentifier(SettingDomainsCell, forIndexPath: indexPath) as! DomainsTableViewCell
                if indexPath.row < setting_swipe_action_items.count {
                    let actionItem = setting_swipe_action_items[indexPath.row]
                    let action = actionItem == .left ? sharedUserDataService.swiftLeft : sharedUserDataService.swiftRight
                    cell.domainText.text = actionItem.description
                    cell.defaultMark.text = action.description
                    cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator;
                }
                return cell
            } else if setting_headers[indexPath.section] == .Storage {
                let cell = tableView.dequeueReusableCellWithIdentifier(SettingStorageCell, forIndexPath: indexPath) as! StorageViewCell
                let usedSpace = sharedUserDataService.usedSpace
                let maxSpace = sharedUserDataService.maxSpace
                cell.setValue(usedSpace, maxSpace: maxSpace)
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                return cell
            }
            else if setting_headers[indexPath.section] == .Debug {
                let cell = tableView.dequeueReusableCellWithIdentifier(SettingGeneralCell, forIndexPath: indexPath) as! GeneralSettingViewCell
                if indexPath.row < setting_debug_items.count {
                    let itme: SDebugItem = setting_debug_items[indexPath.row]
                    cell.LeftText.text = itme.description
                    cell.RightText.text  = ""
                }
                return cell
            }
            else
            {
                let cell = tableView.dequeueReusableCellWithIdentifier(SettingStorageCell, forIndexPath: indexPath) as! UITableViewCell
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                return cell
            }
        }
        else {let cell = tableView.dequeueReusableCellWithIdentifier(SettingStorageCell, forIndexPath: indexPath) as! UITableViewCell
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            return cell
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let  headerCell = tableView.dequeueReusableCellWithIdentifier(HeaderCell) as! CustomHeaderView
        if(setting_headers[section] == SettingSections.Version){
            if let version = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String {
                if let build = NSBundle.mainBundle().infoDictionary?["CFBundleVersion"] as? String {
                    headerCell.headerText.text = NSLocalizedString("Version ") + version + " (\(build))"
                } else {
                    headerCell.headerText.text = NSLocalizedString("Version ") + version
                }
            } else {
                headerCell.headerText.text = NSLocalizedString("Unkonw Version")
            }
        }
        else
        {
            headerCell.headerText.text = setting_headers[section].description
        }
        return headerCell
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return CellHeight;
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if setting_headers[indexPath.section] == SettingSections.General {
            let itme: SGItems = setting_general_items[indexPath.row];
            switch itme {
            case SGItems.NotifyEmail:
                self.performSegueWithIdentifier(NotificationSegue, sender: self)
                break;
            case SGItems.DisplayName:
                self.performSegueWithIdentifier(DisplayNameSegue, sender: self)
                break;
            case SGItems.Signature:
                self.performSegueWithIdentifier(SignatureSegue, sender: self)
                break;
            case SGItems.LoginPWD:
                self.performSegueWithIdentifier(LoginpwdSegue, sender: self)
                break;
            case SGItems.MBP:
                self.performSegueWithIdentifier(MailboxpwdSegue, sender: self)
                break;
            case SGItems.CleanCache:
                if !cleaning {
                    cleaning = true;
                    
                    let window : UIWindow = UIApplication.sharedApplication().windows.last as! UIWindow
                    var  hud : MBProgressHUD = MBProgressHUD.showHUDAddedTo(window, animated: true)
                    hud.labelText = "Reseting message cache ..."
                    hud.removeFromSuperViewOnHide = true
                    //                hud.margin = 10
                    //                hud.yOffset = 150
                    sharedMessageDataService.cleanLocalMessageCache() { task, res, error in
                        hud.mode = MBProgressHUDMode.Text
                        hud.labelText = "Done"
                        hud.hide(true, afterDelay: 1)
                        self.cleaning = false
                    }
                }
                break;
            default:
                break;
            }
        }
        else if setting_headers[indexPath.section] == SettingSections.Debug {
            let itme: SDebugItem = setting_debug_items[indexPath.row];
            switch itme {
            case SDebugItem.Queue:
                self.performSegueWithIdentifier(DebugQueueSegue, sender: self)
                break;
            case SDebugItem.ErrorLogs:
                break;
            case SDebugItem.CleanCache:
                if !cleaning {
                    cleaning = true;
                    
                    let window : UIWindow = UIApplication.sharedApplication().windows.last as! UIWindow
                    var  hud : MBProgressHUD = MBProgressHUD.showHUDAddedTo(window, animated: true)
                    hud.labelText = "Reseting message cache ..."
                    hud.removeFromSuperViewOnHide = true
                    //                hud.margin = 10
                    //                hud.yOffset = 150
                    sharedMessageDataService.cleanLocalMessageCache() { task, res, error in
                        hud.mode = MBProgressHUDMode.Text
                        hud.labelText = "Done"
                        hud.hide(true, afterDelay: 1)
                        self.cleaning = false
                    }
                }
                break;
            }
        } else if setting_headers[indexPath.section] == SettingSections.MultiDomain {
            let alertController = UIAlertController(title: NSLocalizedString("Change default domain to .."), message: nil, preferredStyle: .ActionSheet)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .Cancel, handler: nil))
            var defaultAddress : Address? = nil;
            for (var addr) in multi_domains {
                if addr.status == 1 && addr.receive == 1 {
                    defaultAddress = addr;
                    break
                }
            }
            for (var addr) in multi_domains {
                if addr.status == 1 && addr.receive == 1 {
                    if defaultAddress != addr {
                        alertController.addAction(UIAlertAction(title: addr.email, style: .Default, handler: { (action) -> Void in
                            self.navigationController?.popViewControllerAnimated(true)
                            
                            var newAddrs = Array<Address>()
                            var newOrder = Array<Int>()
                            newAddrs.append(addr);
                            newOrder.append(addr.send);
                            var order = 1;
                            addr.send = order++;
                            for (var oldAddr) in self.multi_domains {
                                if oldAddr != addr {
                                    newAddrs.append(oldAddr)
                                    newOrder.append(oldAddr.send);
                                    oldAddr.send = order++
                                }
                            }
                            ActivityIndicatorHelper.showActivityIndicatorAtView(self.view)
                            sharedUserDataService.updateUserDomiansOrder(newAddrs,  newOrder:newOrder) { _, _, error in
                                tableView.reloadData();
                                ActivityIndicatorHelper.hideActivityIndicatorAtView(self.view)
                                if let error = error {
                                } else {
                                    self.multi_domains = newAddrs
                                    tableView.reloadData()
                                }
                            }
                        }))
                    }
                }
            }
            
            let cell = tableView.cellForRowAtIndexPath(indexPath)
            alertController.popoverPresentationController?.sourceView = cell ?? self.view
            alertController.popoverPresentationController?.sourceRect = (cell == nil ? self.view.frame : cell!.bounds)
            presentViewController(alertController, animated: true, completion: nil)
            
        }  else if setting_headers[indexPath.section] == SettingSections.SwipeAction {
            
            if indexPath.row < setting_swipe_action_items.count {
                
                let actionItem = setting_swipe_action_items[indexPath.row]
                
                let alertController = UIAlertController(title: actionItem.actionDescription, message: nil, preferredStyle: .ActionSheet)
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .Cancel, handler: nil))
                
                let currentAction = actionItem == .left ? sharedUserDataService.swiftLeft : sharedUserDataService.swiftRight
                for (var swipeAction) in setting_swipe_actions {
                    if swipeAction != currentAction {
                        alertController.addAction(UIAlertAction(title: swipeAction.description, style: .Default, handler: { (action) -> Void in
                            self.navigationController?.popViewControllerAnimated(true)
                            
                            ActivityIndicatorHelper.showActivityIndicatorAtView(self.view)
                            sharedUserDataService.updateUserSwipeAction(actionItem == .left, action: swipeAction, completion: { (task, response, error) -> Void in
                                tableView.reloadData()
                                ActivityIndicatorHelper.hideActivityIndicatorAtView(self.view)
                                if let error = error {
                                } else {
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
        return UITableViewCellEditingStyle.None;
    }
    
    func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    func tableView(tableView: UITableView, targetIndexPathForMoveFromRowAtIndexPath sourceIndexPath: NSIndexPath, toProposedIndexPath proposedDestinationIndexPath: NSIndexPath) -> NSIndexPath {
        if sourceIndexPath.section != proposedDestinationIndexPath.section {
            return sourceIndexPath;
        }
        else {
            return proposedDestinationIndexPath;
        }
    }
    
    // Override to support rearranging the table view.
    func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        if setting_headers[fromIndexPath.section] == SettingSections.MultiDomain {
            let val = self.multi_domains.removeAtIndex(fromIndexPath.row)
            self.multi_domains.insert(val, atIndex: toIndexPath.row)
            let indexSet = NSIndexSet(index:fromIndexPath.section)
            tableView.reloadData()
        }
    }
    
}

extension SettingTableViewController {
    
    enum SDebugItem: Int, Printable {
        case Queue = 0
        case ErrorLogs = 1
        case CleanCache = 2
        var description : String {
            switch(self){
            case Queue:
                return NSLocalizedString("Message Queue")
            case ErrorLogs:
                return NSLocalizedString("Error Logs")
            case .CleanCache:
                return NSLocalizedString("Clear Local Message Cache")
            }
        }
    }
    
    enum SGItems: Int, Printable {
        case NotifyEmail = 0
        case DisplayName = 1
        case Signature = 2
        case LoginPWD = 3
        case MBP = 4
        case CleanCache = 5
        case DefaultMobilSign = 6
        var description : String {
            switch(self){
            case NotifyEmail:
                return NSLocalizedString("Notification Email")
            case DisplayName:
                return NSLocalizedString("Display Name")
            case Signature:
                return NSLocalizedString("Signature")
            case LoginPWD:
                return NSLocalizedString("Login Password")
            case MBP:
                return NSLocalizedString("Mailbox Password")
            case .CleanCache:
                return NSLocalizedString("Clear Local Message Cache")
            case .DefaultMobilSign:
                return NSLocalizedString("Default mobile signature")
            }
        }
    }
    
    enum SSwipeActionItems: Int, Printable {
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
    
    enum SettingSections: Int, Printable {
        case Debug = 0
        case General = 1
        case MultiDomain = 2
        case Storage = 3
        case Version = 4
        case SwipeAction = 5
        
        var description : String {
            switch(self){
            case Debug:
                return NSLocalizedString("Debug")
            case General:
                return NSLocalizedString("General Settings")
            case MultiDomain:
                return NSLocalizedString("Multiple Domains")
            case Storage:
                return NSLocalizedString("Storage")
            case Version:
                return NSLocalizedString("")
            case SwipeAction:
                return NSLocalizedString("Message Swipe Actions")
            }
        }
    }
}
